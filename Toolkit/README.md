
# Azure DevOps Permission Matrix Toolkit - PowerShell Scripts

This directory contains PowerShell scripts for comprehensive Azure DevOps permissions auditing and extraction. These scripts help organizations maintain security compliance, perform regular access reviews, and document permission structures across their Azure DevOps environment.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Scripts Description](#scripts-description)
- [Quick Start](#quick-start)
- [Detailed Usage](#detailed-usage)
- [Output Files](#output-files)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🔍 Overview

The Azure DevOps Permission Matrix Toolkit provides automated PowerShell scripts to extract and audit permissions across:

- **Organization Level**: Security groups, users, policies, and organization-wide settings
- **Project Level**: Project-specific groups, teams, and security configurations
- **Repository Level**: Git repository permissions, branch policies, and access controls
- **Pipeline Level**: Build/release pipelines, service connections, agent pools, and variable groups

## 📋 Prerequisites

### Required Software
- **PowerShell 5.1** or **PowerShell 7.x** (recommended)
- **Internet connectivity** for Azure DevOps REST API calls
- **Azure DevOps organization** with appropriate access

### Required Permissions
Your Personal Access Token (PAT) must have the following scopes:
- **Project and Team (read)**
- **Identity (read)**
- **Security (read)**
- **Code (read)** - for repository permissions
- **Build (read)** - for pipeline permissions
- **Release (read)** - for release pipeline permissions
- **Service Connections (read)** - for service connection analysis

### Optional PowerShell Modules
- **ImportExcel** - For consolidated Excel reports (auto-installed if needed)
- **PSRule.Rules.AzureDevOps** - For advanced compliance checking

## 🚀 Installation

### 1. Clone or Download Scripts
```powershell
# If using git
git clone <repository-url>
cd azure_devops_toolkit/scripts

# Or download and extract to a local directory
```

### 2. Set Execution Policy (if needed)
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 3. Create Personal Access Token
1. Navigate to Azure DevOps → User Settings → Personal Access Tokens
2. Create new token with required scopes (see Prerequisites)
3. Store token securely

## 📁 Scripts Description

### Core Extraction Scripts

| Script | Purpose | Output |
|--------|---------|--------|
| `Get-AzureDevOpsOrgPermissions.ps1` | Extract organization-level permissions, security groups, and policies | CSV with org-level data |
| `Get-AzureDevOpsProjectPermissions.ps1` | Extract project-level permissions, teams, and security groups | CSV with project-level data |
| `Get-AzureDevOpsRepoPermissions.ps1` | Extract repository permissions, branch policies, and access controls | CSV with repository data |
| `Get-AzureDevOpsPipelinePermissions.ps1` | Extract pipeline permissions, service connections, and agent pools | CSV with pipeline data |

### Master Orchestration Script

| Script | Purpose | Output |
|--------|---------|--------|
| `Run-AzureDevOpsPermissionAudit.ps1` | Execute all scripts and generate consolidated reports | Multiple CSVs + Summary + Optional Excel |

## 🚀 Quick Start

### Option 1: Run Complete Audit (Recommended)
```powershell
# Set your variables
$orgUrl = "https://dev.azure.com/yourorganization"
$pat = "your-personal-access-token"

# Run complete audit for all projects
.\Run-AzureDevOpsPermissionAudit.ps1 -OrganizationUrl $orgUrl -PersonalAccessToken $pat -GenerateExcelReport

# Run audit for specific project only
.\Run-AzureDevOpsPermissionAudit.ps1 -OrganizationUrl $orgUrl -PersonalAccessToken $pat -ProjectName "MyProject"
```

### Option 2: Run Individual Scripts
```powershell
# Organization permissions
.\Get-AzureDevOpsOrgPermissions.ps1 -OrganizationUrl $orgUrl -PersonalAccessToken $pat

# Project permissions
.\Get-AzureDevOpsProjectPermissions.ps1 -OrganizationUrl $orgUrl -PersonalAccessToken $pat -ProjectName "MyProject"

# Repository permissions
.\Get-AzureDevOpsRepoPermissions.ps1 -OrganizationUrl $orgUrl -ProjectName "MyProject" -PersonalAccessToken $pat

# Pipeline permissions
.\Get-AzureDevOpsPipelinePermissions.ps1 -OrganizationUrl $orgUrl -ProjectName "MyProject" -PersonalAccessToken $pat
```

## 📖 Detailed Usage

### Get-AzureDevOpsOrgPermissions.ps1

Extracts organization-level security information including groups, users, and policies.

```powershell
.\Get-AzureDevOpsOrgPermissions.ps1 `
    -OrganizationUrl "https://dev.azure.com/myorg" `
    -PersonalAccessToken $pat `
    -OutputPath "C:\Reports\org_permissions.csv"
```

**Parameters:**
- `OrganizationUrl` (Required): Your Azure DevOps organization URL
- `PersonalAccessToken` (Required): PAT with appropriate permissions
- `OutputPath` (Optional): Custom output file path

### Get-AzureDevOpsProjectPermissions.ps1

Extracts project-level permissions, teams, and security groups.

```powershell
# Analyze all projects
.\Get-AzureDevOpsProjectPermissions.ps1 `
    -OrganizationUrl "https://dev.azure.com/myorg" `
    -PersonalAccessToken $pat

# Analyze specific project
.\Get-AzureDevOpsProjectPermissions.ps1 `
    -OrganizationUrl "https://dev.azure.com/myorg" `
    -ProjectName "MyProject" `
    -PersonalAccessToken $pat
```

**Parameters:**
- `OrganizationUrl` (Required): Your Azure DevOps organization URL
- `ProjectName` (Optional): Specific project name (analyzes all if omitted)
- `PersonalAccessToken` (Required): PAT with appropriate permissions
- `OutputPath` (Optional): Custom output file path

### Get-AzureDevOpsRepoPermissions.ps1

Extracts repository permissions, branch policies, and security settings.

```powershell
# Analyze all repositories in project
.\Get-AzureDevOpsRepoPermissions.ps1 `
    -OrganizationUrl "https://dev.azure.com/myorg" `
    -ProjectName "MyProject" `
    -PersonalAccessToken $pat

# Analyze specific repository
.\Get-AzureDevOpsRepoPermissions.ps1 `
    -OrganizationUrl "https://dev.azure.com/myorg" `
    -ProjectName "MyProject" `
    -RepositoryName "MyRepo" `
    -PersonalAccessToken $pat
```

**Parameters:**
- `OrganizationUrl` (Required): Your Azure DevOps organization URL
- `ProjectName` (Required): Project name containing repositories
- `RepositoryName` (Optional): Specific repository name (analyzes all if omitted)
- `PersonalAccessToken` (Required): PAT with appropriate permissions
- `OutputPath` (Optional): Custom output file path

### Get-AzureDevOpsPipelinePermissions.ps1

Extracts pipeline permissions, service connections, agent pools, and variable groups.

```powershell
# Analyze all pipeline types
.\Get-AzureDevOpsPipelinePermissions.ps1 `
    -OrganizationUrl "https://dev.azure.com/myorg" `
    -ProjectName "MyProject" `
    -PersonalAccessToken $pat

# Analyze only build pipelines
.\Get-AzureDevOpsPipelinePermissions.ps1 `
    -OrganizationUrl "https://dev.azure.com/myorg" `
    -ProjectName "MyProject" `
    -PipelineType "Build" `
    -PersonalAccessToken $pat
```

**Parameters:**
- `OrganizationUrl` (Required): Your Azure DevOps organization URL
- `ProjectName` (Required): Project name containing pipelines
- `PipelineType` (Optional): "Build", "Release", or "Both" (default: Both)
- `PersonalAccessToken` (Required): PAT with appropriate permissions
- `OutputPath` (Optional): Custom output file path

### Run-AzureDevOpsPermissionAudit.ps1

Master script that orchestrates all permission extractions and generates consolidated reports.

```powershell
# Complete audit with Excel report
.\Run-AzureDevOpsPermissionAudit.ps1 `
    -OrganizationUrl "https://dev.azure.com/myorg" `
    -PersonalAccessToken $pat `
    -GenerateExcelReport

# Audit specific project with custom output directory
.\Run-AzureDevOpsPermissionAudit.ps1 `
    -OrganizationUrl "https://dev.azure.com/myorg" `
    -PersonalAccessToken $pat `
    -ProjectName "MyProject" `
    -OutputDirectory "C:\AuditReports\MyProject"
```

**Parameters:**
- `OrganizationUrl` (Required): Your Azure DevOps organization URL
- `PersonalAccessToken` (Required): PAT with appropriate permissions
- `ProjectName` (Optional): Specific project name (analyzes all if omitted)
- `OutputDirectory` (Optional): Custom output directory
- `GenerateExcelReport` (Switch): Generate consolidated Excel workbook

## 📄 Output Files

### Individual Script Outputs
Each script generates a timestamped CSV file with extracted permissions data:

- `org_permissions_YYYYMMDD_HHMMSS.csv` - Organization-level data
- `project_permissions_YYYYMMDD_HHMMSS.csv` - Project-level data
- `repo_permissions_YYYYMMDD_HHMMSS.csv` - Repository-level data
- `pipeline_permissions_YYYYMMDD_HHMMSS.csv` - Pipeline-level data

### Master Script Outputs
The master script creates a structured directory with:

```
AzureDevOps_Audit_YYYYMMDD_HHMMSS/
├── org_permissions.csv
├── project_permissions.csv
├── repo_permissions_ProjectName.csv
├── pipeline_permissions_ProjectName.csv
├── SUMMARY_REPORT.md
└── Azure_DevOps_Permissions_Audit.xlsx (if -GenerateExcelReport used)
```

### Summary Report
The `SUMMARY_REPORT.md` file includes:
- Audit metadata (timestamp, scope, organization)
- File inventory with record counts
- Key findings and recommendations
- Compliance considerations
- Next steps for remediation

## 🔒 Security Considerations

### Personal Access Token Security
- **Minimum Permissions**: Only grant required scopes to PAT
- **Secure Storage**: Store PAT in Azure Key Vault or secure credential manager
- **Regular Rotation**: Rotate PATs every 90 days or per organizational policy
- **Environment Variables**: Use environment variables instead of hardcoding tokens

```powershell
# Example: Using environment variable
$pat = $env:AZURE_DEVOPS_PAT
```

### Data Protection
- **Sensitive Data**: Output files may contain sensitive permission information
- **Access Control**: Restrict access to output files and directories
- **Retention**: Follow data retention policies for audit files
- **Encryption**: Consider encrypting output files for long-term storage

### Network Security
- **HTTPS Only**: All API calls use HTTPS encryption
- **Firewall**: Ensure outbound HTTPS (443) access to dev.azure.com
- **Proxy**: Configure proxy settings if required by your organization

## 🔧 Troubleshooting

### Common Issues

#### Authentication Errors
```
Error: API call failed: 401 Unauthorized
```
**Solution**: Verify PAT is valid and has required permissions

#### Network Connectivity
```
Error: Unable to connect to the remote server
```
**Solution**: Check internet connectivity and firewall settings

#### Permission Denied
```
Error: Access denied for resource
```
**Solution**: Ensure PAT has appropriate scopes for the resource being accessed

#### Large Organization Timeouts
```
Error: The operation has timed out
```
**Solution**: Run scripts for individual projects instead of entire organization

### Debug Mode
Enable verbose output for troubleshooting:

```powershell
$VerbosePreference = "Continue"
.\Get-AzureDevOpsOrgPermissions.ps1 -OrganizationUrl $orgUrl -PersonalAccessToken $pat -Verbose
```

### API Rate Limiting
If you encounter rate limiting:
- Add delays between API calls
- Process smaller batches of resources
- Use the master script which includes built-in throttling

## 📊 Best Practices

### Regular Auditing
- **Schedule**: Run audits monthly or quarterly
- **Automation**: Use Azure Automation or scheduled tasks
- **Comparison**: Compare results over time to identify changes
- **Alerts**: Set up alerts for significant permission changes

### Compliance
- **Documentation**: Maintain audit trails for compliance requirements
- **Review Process**: Establish regular access review processes
- **Least Privilege**: Use audit results to implement least privilege access
- **Segregation**: Ensure proper separation of duties

### Performance Optimization
- **Targeted Audits**: Focus on specific projects or resources when possible
- **Parallel Processing**: Run multiple project audits in parallel
- **Incremental Updates**: Track changes since last audit
- **Caching**: Cache organization-level data for multiple project audits

## 🤝 Contributing

We welcome contributions to improve these scripts! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add appropriate tests
5. Submit a pull request

### Development Guidelines
- Follow PowerShell best practices
- Include proper error handling
- Add comprehensive help documentation
- Test with multiple Azure DevOps configurations

## 📞 Support

For issues and questions:
- Check the troubleshooting section above
- Review Azure DevOps REST API documentation
- Open an issue in the repository
- Contact your Azure DevOps administrator

## 📚 Additional Resources

- [Azure DevOps REST API Documentation](https://learn.microsoft.com/en-us/rest/api/azure/devops/)
- [Azure DevOps Security Best Practices](https://learn.microsoft.com/en-us/azure/devops/organizations/security/)
- [PowerShell Documentation](https://docs.microsoft.com/en-us/powershell/)
- [Azure DevOps Permissions Reference](https://learn.microsoft.com/en-us/azure/devops/organizations/security/permissions)

---

**Last Updated**: June 2025  
**Version**: 2.0  
**Compatibility**: Azure DevOps Services, Azure DevOps Server 2020+
