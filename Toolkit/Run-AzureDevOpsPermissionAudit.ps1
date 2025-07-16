<#
.SYNOPSIS
    Master script to run comprehensive Azure DevOps permissions audit
.DESCRIPTION
    This script orchestrates the execution of all permission extraction scripts and generates
    a consolidated report with summary dashboard and recommendations.
.PARAMETER OrganizationUrl
    The URL of your Azure DevOps organization (e.g., https://dev.azure.com/yourorg)
.PARAMETER PersonalAccessToken
    Personal Access Token with appropriate permissions to read all settings
.PARAMETER ProjectName
    Specific project to analyze (optional - if not provided, analyzes all projects)
.PARAMETER OutputDirectory
    Directory where all output files will be saved (default: dynamic based on script location)
.PARAMETER GenerateExcelReport
    Switch to generate consolidated Excel report (requires ImportExcel module)
.EXAMPLE
    .\Run-AzureDevOpsPermissionAudit.ps1 -OrganizationUrl "https://dev.azure.com/myorg" -PersonalAccessToken $pat -GenerateExcelReport
.NOTES
    Requires PowerShell 5.1 or later
    Author: Azure DevOps Security Toolkit
    Version: 2.0 (Security Enhanced)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, HelpMessage="Azure DevOps organization URL")]
    [ValidatePattern('^https://dev\.azure\.com/[a-zA-Z0-9\-_]+/?$|^https://[a-zA-Z0-9\-_]+\.visualstudio\.com/?$')]
    [ValidateNotNullOrEmpty()]
    [string]$OrganizationUrl,
    
    [Parameter(Mandatory=$true, HelpMessage="Personal Access Token with required permissions")]
    [ValidateNotNullOrEmpty()]
    [ValidateLength(52, 52)]
    [string]$PersonalAccessToken,
    
    [Parameter(Mandatory=$false, HelpMessage="Specific project name to analyze")]
    [ValidateLength(1, 64)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false, HelpMessage="Output directory path")]
    [ValidateScript({
        if ($_ -and -not (Test-Path (Split-Path $_ -Parent) -PathType Container)) {
            throw "Parent directory of specified path does not exist: $(Split-Path $_ -Parent)"
        }
        return $true
    })]
    [string]$OutputDirectory,
    
    [Parameter(Mandatory=$false, HelpMessage="Generate consolidated Excel report")]
    [switch]$GenerateExcelReport
)

# Security: Clear error action preference and set strict mode
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Prerequisites check
function Test-Prerequisites {
    [CmdletBinding()]
    param()
    
    try {
        # Check PowerShell version
        if ($PSVersionTable.PSVersion.Major -lt 5) {
            throw [System.InvalidOperationException]::new("PowerShell 5.1 or later is required. Current version: $($PSVersionTable.PSVersion)")
        }
        
        # Check if running on supported OS
        if ($PSVersionTable.Platform -and $PSVersionTable.Platform -ne 'Win32NT' -and $PSVersionTable.Platform -ne 'Unix') {
            Write-Warning "Script may not function correctly on platform: $($PSVersionTable.Platform)"
        }
        
        Write-Verbose "Prerequisites check passed - PowerShell $($PSVersionTable.PSVersion)"
        return $true
    }
    catch {
        Write-Error "Prerequisites check failed: $($_.Exception.Message)" -ErrorId 'PrerequisitesCheckFailed'
        return $false
    }
}

# Function to create secure string and handle PAT securely
function ConvertTo-SecurePAT {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PlainTextPAT
    )
    
    try {
        $secureString = ConvertTo-SecureString -String $PlainTextPAT -AsPlainText -Force
        return $secureString
    }
    catch {
        throw [System.Security.SecurityException]::new("Failed to convert PAT to secure string: $($_.Exception.Message)")
    }
}

# Function to safely create file names
function New-SafeFileName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$BaseName,
        
        [Parameter(Mandatory=$false)]
        [string]$Extension = '.csv',
        
        [Parameter(Mandatory=$false)]
        [string]$Suffix
    )
    
    try {
        # Remove invalid characters
        $invalidChars = [IO.Path]::GetInvalidFileNameChars() -join ''
        $safeName = $BaseName -replace "[$([regex]::Escape($invalidChars))]", '_'
        
        # Add suffix if provided
        if ($Suffix) {
            $safeSuffix = $Suffix -replace "[$([regex]::Escape($invalidChars))]", '_'
            $safeName = "${safeName}_${safeSuffix}"
        }
        
        # Add timestamp to prevent collisions
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $finalName = "${safeName}_${timestamp}${Extension}"
        
        # Ensure name isn't too long (Windows has 260 char limit for full path)
        if ($finalName.Length -gt 100) {
            $finalName = $finalName.Substring(0, 90) + "_trunc${Extension}"
        }
        
        return $finalName
    }
    catch {
        throw [System.IO.InvalidDataException]::new("Failed to create safe filename: $($_.Exception.Message)")
    }
}

# Function to check if required modules are installed
function Test-RequiredModules {
    [CmdletBinding()]
    param()
    
    try {
        $requiredModules = @()
        
        if ($GenerateExcelReport) {
            $requiredModules += "ImportExcel"
        }
        
        foreach ($module in $requiredModules) {
            if (-not (Get-Module -ListAvailable -Name $module)) {
                Write-Warning "Required module '$module' is not installed."
                
                # Non-interactive check for CI/CD environments
                if ([Environment]::UserInteractive) {
                    $install = Read-Host "Would you like to install it now? (Y/N)"
                    if ($install -eq 'Y' -or $install -eq 'y') {
                        try {
                            Write-Host "Installing module '$module'..." -ForegroundColor Yellow
                            Install-Module -Name $module -Force -Scope CurrentUser -AllowClobber
                            Write-Host "Module '$module' installed successfully." -ForegroundColor Green
                        }
                        catch {
                            throw [System.InvalidOperationException]::new("Failed to install module '$module': $($_.Exception.Message)")
                        }
                    } else {
                        throw [System.InvalidOperationException]::new("Cannot proceed without required module '$module'")
                    }
                } else {
                    throw [System.InvalidOperationException]::new("Required module '$module' is not installed and cannot install in non-interactive mode")
                }
            }
        }
        return $true
    }
    catch {
        Write-Error "Module validation failed: $($_.Exception.Message)" -ErrorId 'ModuleValidationFailed'
        return $false
    }
}

# Secure function to run individual permission scripts using parameter splatting
function Invoke-PermissionScript {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$ScriptPath,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Parameters,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Description
    )
    
    Write-Host "Running $Description..." -ForegroundColor Yellow
    Write-Verbose "Script: $ScriptPath"
    Write-Verbose "Parameters: $($Parameters.Keys -join ', ')"
    
    try {
        # Security: Use parameter splatting instead of Invoke-Expression
        # This prevents code injection vulnerabilities
        $result = & $ScriptPath @Parameters
        
        # Check for script execution success
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            Write-Host "$Description completed successfully." -ForegroundColor Green
            return $true
        } else {
            Write-Warning "$Description completed with exit code: $LASTEXITCODE"
            return $false
        }
    }
    catch [System.Management.Automation.CommandNotFoundException] {
        throw [System.IO.FileNotFoundException]::new("Script not found or not executable: $ScriptPath")
    }
    catch [System.UnauthorizedAccessException] {
        throw [System.UnauthorizedAccessException]::new("Access denied executing script: $ScriptPath. Check execution policy and permissions.")
    }
    catch {
        throw [System.InvalidOperationException]::new("$Description failed: $($_.Exception.Message)")
    }
}

# Function to generate summary report with enhanced error handling
function New-SummaryReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$OutputDir,
        
        [Parameter(Mandatory=$true)]
        [array]$CsvFiles
    )
    
    try {
        $summaryPath = Join-Path $OutputDir "SUMMARY_REPORT.md"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Sanitize organization URL for display
        $sanitizedOrgUrl = $OrganizationUrl -replace '([?&].*)', '' # Remove query parameters if any
        
        $summary = @"
# Azure DevOps Permissions Audit Summary Report

**Generated:** $timestamp  
**Organization:** $sanitizedOrgUrl  
**Audit Scope:** $(if ($ProjectName) { "Project: $ProjectName" } else { "All Projects" })
**Script Version:** 2.0 (Security Enhanced)

## Files Generated

"@
        
        $totalItems = 0
        foreach ($file in $CsvFiles) {
            if (Test-Path $file) {
                try {
                    $data = Import-Csv $file
                    $itemCount = $data.Count
                    $totalItems += $itemCount
                    $fileName = Split-Path $file -Leaf
                    $summary += "- **$fileName**: $itemCount items`n"
                }
                catch {
                    Write-Warning "Could not read CSV file: $file - $($_.Exception.Message)"
                    $fileName = Split-Path $file -Leaf
                    $summary += "- **$fileName**: Error reading file`n"
                }
            }
        }
        
        $summary += "`n**Total Items Audited:** $totalItems`n`n"
        
        $summary += @"

## Key Findings and Recommendations

### Security Groups Analysis
- Review organization-level administrators (Project Collection Administrators)
- Validate project-level permissions alignment with business requirements
- Ensure proper separation of duties

### Repository Security
- Verify branch policies are enforced on main/master branches
- Check for appropriate code review requirements
- Validate repository permissions follow least privilege principle

### Pipeline Security
- Review service connection permissions and scoping
- Validate agent pool access controls
- Check variable group security and secret management

### Compliance Considerations
- Ensure audit logging is enabled and monitored
- Validate user access reviews are conducted regularly
- Check for proper offboarding procedures

## Security Recommendations
1. **Regular Audits**: Schedule quarterly permission reviews
2. **Least Privilege**: Apply minimum required permissions
3. **Access Reviews**: Implement automated access certification
4. **Monitoring**: Enable and monitor Azure DevOps audit logs
5. **Documentation**: Maintain current permission documentation

## Next Steps
1. Review detailed CSV files for specific permission assignments
2. Identify and remediate any permission violations
3. Implement regular permission audits (quarterly recommended)
4. Update security group memberships as needed
5. Document and communicate any changes to stakeholders

---
*This report was generated using the Azure DevOps Permission Matrix Toolkit v2.0*  
*Report generated on: $([Environment]::MachineName) by $([Environment]::UserName)*
"@
        
        $summary | Out-File -FilePath $summaryPath -Encoding UTF8
        Write-Host "Summary report generated: $summaryPath" -ForegroundColor Green
        return $summaryPath
    }
    catch {
        throw [System.IO.IOException]::new("Failed to generate summary report: $($_.Exception.Message)")
    }
}

# Function to generate Excel report with enhanced error handling
function New-ExcelReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateScript({Test-Path $_ -PathType Container})]
        [string]$OutputDir,
        
        [Parameter(Mandatory=$true)]
        [array]$CsvFiles
    )
    
    if (-not $GenerateExcelReport) { 
        Write-Verbose "Excel report generation skipped"
        return 
    }
    
    try {
        Import-Module ImportExcel -Force
        
        $excelFileName = New-SafeFileName -BaseName "Azure_DevOps_Permissions_Audit" -Extension ".xlsx"
        $excelPath = Join-Path $OutputDir $excelFileName
        
        # Create summary sheet
        $summaryData = @()
        foreach ($file in $CsvFiles) {
            if (Test-Path $file) {
                try {
                    $data = Import-Csv $file
                    $fileName = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $file -Leaf))
                    $summaryData += [PSCustomObject]@{
                        DataType = $fileName
                        RecordCount = $data.Count
                        FilePath = Split-Path $file -Leaf  # Only show filename for security
                        LastModified = (Get-Item $file).LastWriteTime
                        FileSize = "{0:N2} KB" -f ((Get-Item $file).Length / 1KB)
                    }
                }
                catch {
                    Write-Warning "Could not process file for Excel report: $file - $($_.Exception.Message)"
                }
            }
        }
        
        if ($summaryData.Count -gt 0) {
            $summaryData | Export-Excel -Path $excelPath -WorksheetName "Summary" -AutoSize -BoldTopRow -FreezeTopRow
        }
        
        # Add each CSV as a separate worksheet
        foreach ($file in $CsvFiles) {
            if (Test-Path $file) {
                try {
                    $data = Import-Csv $file
                    if ($data.Count -gt 0) {
                        $sheetName = [System.IO.Path]::GetFileNameWithoutExtension((Split-Path $file -Leaf))
                        $sheetName = $sheetName -replace ".*_permissions_.*", "" -replace "_", " "
                        $sheetName = (Get-Culture).TextInfo.ToTitleCase($sheetName)
                        
                        # Excel worksheet name limitations
                        if ($sheetName.Length -gt 31) { 
                            $sheetName = $sheetName.Substring(0, 28) + "..."
                        }
                        
                        # Remove invalid characters for worksheet names
                        $sheetName = $sheetName -replace '[\\\/\?\*\[\]]', '_'
                        
                        $data | Export-Excel -Path $excelPath -WorksheetName $sheetName -AutoSize -BoldTopRow -FreezeTopRow
                    }
                }
                catch {
                    Write-Warning "Could not add worksheet for file: $file - $($_.Exception.Message)"
                }
            }
        }
        
        Write-Host "Excel report generated: $excelPath" -ForegroundColor Green
        return $excelPath
    }
    catch {
        throw [System.InvalidOperationException]::new("Failed to generate Excel report: $($_.Exception.Message)")
    }
}

# Function to validate Azure DevOps connectivity
function Test-AzureDevOpsConnectivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$OrgUrl,
        
        [Parameter(Mandatory=$true)]
        [System.Security.SecureString]$SecurePAT
    )
    
    try {
        # Convert secure string back to plain text for API call
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePAT)
        $plainPAT = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        
        try {
            $headers = @{
                Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$plainPAT")))"
                'Content-Type' = 'application/json'
            }
            
            $testUri = "$OrgUrl/_apis/profile/profiles/me?api-version=7.1-preview.3"
            $response = Invoke-RestMethod -Uri $testUri -Headers $headers -Method GET -TimeoutSec 30
            
            if ($response) {
                Write-Verbose "Successfully connected to Azure DevOps as: $($response.displayName)"
                return $true
            }
        }
        finally {
            # Security: Clear plain text PAT from memory
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
            if ($plainPAT) {
                $plainPAT = $null
            }
        }
    }
    catch [System.Net.WebException] {
        throw [System.UnauthorizedAccessException]::new("Authentication failed. Please verify your Personal Access Token has the required permissions.")
    }
    catch {
        throw [System.Net.NetworkInformation.NetworkInformationException]::new("Failed to connect to Azure DevOps: $($_.Exception.Message)")
    }
}

# Main execution with comprehensive error handling
try {
    Write-Host "Azure DevOps Comprehensive Permissions Audit v2.0 (Security Enhanced)" -ForegroundColor Green
    Write-Host "=================================================================" -ForegroundColor Green
    
    # Prerequisites validation
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    if (-not (Test-Prerequisites)) {
        exit 1
    }
    
    # Normalize organization URL
    $OrganizationUrl = $OrganizationUrl.TrimEnd('/')
    Write-Host "Organization: $OrganizationUrl" -ForegroundColor Cyan
    
    # Convert PAT to secure string
    Write-Host "Securing Personal Access Token..." -ForegroundColor Yellow
    $securePAT = ConvertTo-SecurePAT -PlainTextPAT $PersonalAccessToken
    
    # Clear the original PAT from memory for security
    $PersonalAccessToken = $null
    [System.GC]::Collect()
    
    # Test connectivity
    Write-Host "Testing Azure DevOps connectivity..." -ForegroundColor Yellow
    Test-AzureDevOpsConnectivity -OrgUrl $OrganizationUrl -SecurePAT $securePAT
    Write-Host "Connection successful!" -ForegroundColor Green
    
    # Set default output directory if not provided
    if (-not $OutputDirectory) {
        $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
        $OutputDirectory = Join-Path $PSScriptRoot "AzureDevOps_Audit_$timestamp"
    }
    
    Write-Host "Output Directory: $OutputDirectory" -ForegroundColor Cyan
    
    # Validate prerequisites and modules
    Write-Host "Validating required modules..." -ForegroundColor Yellow
    if (-not (Test-RequiredModules)) {
        exit 1
    }
    
    # Create output directory
    if (-not (Test-Path $OutputDirectory)) {
        try {
            New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
            Write-Host "Created output directory: $OutputDirectory" -ForegroundColor Green
        }
        catch {
            throw [System.IO.DirectoryNotFoundException]::new("Failed to create output directory: $($_.Exception.Message)")
        }
    }
    
    # Get script directory dynamically (cross-platform compatible)
    $scriptDir = $PSScriptRoot
    if (-not $scriptDir) {
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    
    Write-Verbose "Script directory: $scriptDir"
    $csvFiles = @()
    
    # Convert secure PAT back to plain text for script parameters (done securely)
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePAT)
    $plainPATForScripts = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    
    try {
        # Run organization permissions script
        $orgScript = Join-Path $scriptDir "Get-AzureDevOpsOrgPermissions.ps1"
        $orgOutputName = New-SafeFileName -BaseName "org_permissions"
        $orgOutput = Join-Path $OutputDirectory $orgOutputName
        $orgParams = @{
            OrganizationUrl = $OrganizationUrl
            PersonalAccessToken = $plainPATForScripts
            OutputPath = $orgOutput
        }
        
        if (Test-Path $orgScript) {
            Write-Host "Running Organization Permissions Analysis..." -ForegroundColor Yellow
            if (Invoke-PermissionScript -ScriptPath $orgScript -Parameters $orgParams -Description "Organization Permissions Extraction") {
                $csvFiles += $orgOutput
            }
        } else {
            Write-Warning "Organization permissions script not found: $orgScript"
        }
        
        # Run project permissions script
        $projectScript = Join-Path $scriptDir "Get-AzureDevOpsProjectPermissions.ps1"
        $projectOutputName = New-SafeFileName -BaseName "project_permissions"
        $projectOutput = Join-Path $OutputDirectory $projectOutputName
        $projectParams = @{
            OrganizationUrl = $OrganizationUrl
            PersonalAccessToken = $plainPATForScripts
            OutputPath = $projectOutput
        }
        if ($ProjectName) { 
            $projectParams.ProjectName = $ProjectName 
        }
        
        if (Test-Path $projectScript) {
            Write-Host "Running Project Permissions Analysis..." -ForegroundColor Yellow
            if (Invoke-PermissionScript -ScriptPath $projectScript -Parameters $projectParams -Description "Project Permissions Extraction") {
                $csvFiles += $projectOutput
            }
        } else {
            Write-Warning "Project permissions script not found: $projectScript"
        }
        
        # Get list of projects for repository and pipeline analysis
        Write-Host "Retrieving projects list..." -ForegroundColor Yellow
        $headers = @{Authorization = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$plainPATForScripts")))"}
        $projectsToAnalyze = @()
        
        if ($ProjectName) {
            $projectsToAnalyze = @($ProjectName)
            Write-Host "Analyzing single project: $ProjectName" -ForegroundColor Cyan
        } else {
            try {
                $projectsUri = "$OrganizationUrl/_apis/projects?api-version=7.1-preview.4"
                $projects = Invoke-RestMethod -Uri $projectsUri -Headers $headers -Method GET -TimeoutSec 30
                if ($projects -and $projects.value) {
                    $projectsToAnalyze = $projects.value | ForEach-Object { $_.name }
                    Write-Host "Found $($projectsToAnalyze.Count) projects to analyze" -ForegroundColor Cyan
                }
            }
            catch {
                Write-Warning "Could not retrieve projects list: $($_.Exception.Message). Repository and pipeline analysis will be skipped."
            }
        }
        
        # Run repository and pipeline scripts for each project
        foreach ($project in $projectsToAnalyze) {
            Write-Host "Analyzing project: $project" -ForegroundColor Yellow
            
            # Repository permissions
            $repoScript = Join-Path $scriptDir "Get-AzureDevOpsRepoPermissions.ps1"
            $repoOutputName = New-SafeFileName -BaseName "repo_permissions" -Suffix $project
            $repoOutput = Join-Path $OutputDirectory $repoOutputName
            $repoParams = @{
                OrganizationUrl = $OrganizationUrl
                ProjectName = $project
                PersonalAccessToken = $plainPATForScripts
                OutputPath = $repoOutput
            }
            
            if (Test-Path $repoScript) {
                if (Invoke-PermissionScript -ScriptPath $repoScript -Parameters $repoParams -Description "Repository Permissions for $project") {
                    $csvFiles += $repoOutput
                }
            } else {
                Write-Warning "Repository permissions script not found: $repoScript"
            }
            
            # Pipeline permissions
            $pipelineScript = Join-Path $scriptDir "Get-AzureDevOpsPipelinePermissions.ps1"
            $pipelineOutputName = New-SafeFileName -BaseName "pipeline_permissions" -Suffix $project
            $pipelineOutput = Join-Path $OutputDirectory $pipelineOutputName
            $pipelineParams = @{
                OrganizationUrl = $OrganizationUrl
                ProjectName = $project
                PersonalAccessToken = $plainPATForScripts
                OutputPath = $pipelineOutput
            }
            
            if (Test-Path $pipelineScript) {
                if (Invoke-PermissionScript -ScriptPath $pipelineScript -Parameters $pipelineParams -Description "Pipeline Permissions for $project") {
                    $csvFiles += $pipelineOutput
                }
            } else {
                Write-Warning "Pipeline permissions script not found: $pipelineScript"
            }
        }
        
        # Generate reports
        Write-Host "Generating summary report..." -ForegroundColor Yellow
        $summaryPath = New-SummaryReport -OutputDir $OutputDirectory -CsvFiles $csvFiles
        
        # Generate Excel report if requested
        if ($GenerateExcelReport) {
            Write-Host "Generating Excel report..." -ForegroundColor Yellow
            $excelPath = New-ExcelReport -OutputDir $OutputDirectory -CsvFiles $csvFiles
        }
        
        # Final summary
        Write-Host "`n=================================================================" -ForegroundColor Green
        Write-Host "Audit completed successfully!" -ForegroundColor Green
        Write-Host "Results saved to: $OutputDirectory" -ForegroundColor Cyan
        Write-Host "Files generated:" -ForegroundColor Cyan
        Write-Host "  - CSV files: $($csvFiles.Count)" -ForegroundColor White
        Write-Host "  - Summary report: SUMMARY_REPORT.md" -ForegroundColor White
        
        if ($GenerateExcelReport -and $excelPath) {
            Write-Host "  - Excel report: $(Split-Path $excelPath -Leaf)" -ForegroundColor White
        }
        
        Write-Host "`nNext steps:" -ForegroundColor Yellow
        Write-Host "1. Review the summary report for key findings" -ForegroundColor White
        Write-Host "2. Analyze detailed CSV files for specific permissions" -ForegroundColor White
        Write-Host "3. Implement recommended security improvements" -ForegroundColor White
        Write-Host "=================================================================" -ForegroundColor Green
    }
    finally {
        # Security: Clear PAT from memory
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
        if ($plainPATForScripts) {
            $plainPATForScripts = $null
        }
        if ($securePAT) {
            $securePAT.Dispose()
        }
        [System.GC]::Collect()
    }
}
catch [System.UnauthorizedAccessException] {
    Write-Error "Access denied: $($_.Exception.Message)" -ErrorId 'AccessDenied'
    exit 2
}
catch [System.Net.NetworkInformation.NetworkInformationException] {
    Write-Error "Network connectivity issue: $($_.Exception.Message)" -ErrorId 'NetworkError'
    exit 3
}
catch [System.IO.DirectoryNotFoundException] {
    Write-Error "Directory not found: $($_.Exception.Message)" -ErrorId 'DirectoryNotFound'
    exit 4
}
catch [System.InvalidOperationException] {
    Write-Error "Operation failed: $($_.Exception.Message)" -ErrorId 'OperationFailed'
    exit 5
}
catch {
    Write-Error "Audit execution failed: $($_.Exception.Message)" -ErrorId 'AuditExecutionFailed'
    Write-Error "Stack trace: $($_.ScriptStackTrace)" -ErrorId 'StackTrace'
    exit 1
}
finally {
    # Final cleanup
    if ($securePAT) {
        $securePAT.Dispose()
    }
    [System.GC]::Collect()
}
