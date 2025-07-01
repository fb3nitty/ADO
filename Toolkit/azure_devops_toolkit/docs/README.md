
# Azure DevOps Permission Matrix Toolkit

A comprehensive toolkit for IT administrators to audit, analyze, and manage Azure DevOps Services permissions across organizations, projects, repositories, and pipelines.

## Overview

The Azure DevOps Permission Matrix Toolkit provides a complete solution for understanding and managing permissions in Azure DevOps Services environments. This toolkit is designed for IT administrators, security teams, and DevOps engineers who need to maintain proper access controls and compliance in their Azure DevOps organizations.

## Features

- **Comprehensive Permission Extraction**: Extract permissions from all levels of Azure DevOps hierarchy
- **Multi-Level Analysis**: Organization, project, repository, and pipeline permission auditing
- **Excel Integration**: Generate professional Excel reports with multiple worksheets
- **Automated Workflows**: Master script orchestrates complete audit processes
- **Security Best Practices**: Built-in recommendations and compliance guidance
- **Flexible Reporting**: CSV and Excel output formats with customizable templates

## Package Contents

### PowerShell Scripts (`/scripts`)
- `Get-AzureDevOpsOrgPermissions.ps1` - Organization-level permissions extraction
- `Get-AzureDevOpsProjectPermissions.ps1` - Project-level permissions and teams analysis
- `Get-AzureDevOpsRepoPermissions.ps1` - Repository permissions and branch policies
- `Get-AzureDevOpsPipelinePermissions.ps1` - Pipeline, service connections, and agent pools
- `Run-AzureDevOpsPermissionAudit.ps1` - Master orchestration script

### Excel Templates (`/templates`)
- `permission_matrix.xlsx` - Comprehensive permission matrix template with multiple worksheets

### Documentation (`/docs`)
- `INSTALL.md` - Installation and setup instructions
- `TROUBLESHOOT.md` - Common issues and solutions
- `BEST_PRACTICES.md` - Security and permission management best practices

### Workflow Checklists (`/checklists`)
- `checklist.md` / `checklist.pdf` - Step-by-step Azure DevOps setup and security checklist

## Quick Start

### Prerequisites
- PowerShell 5.1 or later
- Azure DevOps Services organization access
- Personal Access Token with appropriate permissions
- Optional: ImportExcel PowerShell module for Excel report generation

### Basic Usage

1. **Single Project Audit**:
```powershell
.\Run-AzureDevOpsPermissionAudit.ps1 -OrganizationUrl "https://dev.azure.com/yourorg" -PersonalAccessToken $pat -ProjectName "YourProject"
```

2. **Organization-Wide Audit**:
```powershell
.\Run-AzureDevOpsPermissionAudit.ps1 -OrganizationUrl "https://dev.azure.com/yourorg" -PersonalAccessToken $pat -GenerateExcelReport
```

3. **Individual Component Analysis**:
```powershell
.\Get-AzureDevOpsOrgPermissions.ps1 -OrganizationUrl "https://dev.azure.com/yourorg" -PersonalAccessToken $pat
```

## Required Permissions

Your Personal Access Token must have the following scopes:
- **Project and Team**: Read
- **Identity**: Read
- **Security**: Manage
- **Code**: Read
- **Build**: Read
- **Release**: Read
- **Service Connections**: Read
- **Agent Pools**: Read

## Output Files

The toolkit generates several types of output files:

### CSV Reports
- `org_permissions.csv` - Organization-level security groups and users
- `project_permissions.csv` - Project-level groups, teams, and permissions
- `repo_permissions_[project].csv` - Repository permissions and branch policies
- `pipeline_permissions_[project].csv` - Pipeline permissions and related resources

### Summary Reports
- `SUMMARY_REPORT.md` - Executive summary with key findings and recommendations
- `Azure_DevOps_Permissions_Audit.xlsx` - Consolidated Excel workbook (optional)

## Security Considerations

- **Token Security**: Store Personal Access Tokens securely and use minimal required scopes
- **Data Handling**: Audit reports may contain sensitive information - handle appropriately
- **Regular Audits**: Run permission audits regularly (quarterly recommended)
- **Access Reviews**: Use reports to conduct regular access reviews and cleanup

## Support and Troubleshooting

For common issues and solutions, see:
- `docs/TROUBLESHOOT.md` - Detailed troubleshooting guide
- `docs/BEST_PRACTICES.md` - Security and operational best practices

## Version Information

**Version**: 1.0  
**Compatibility**: Azure DevOps Services (cloud)  
**PowerShell**: 5.1+ (Windows), 7.0+ (Cross-platform)

## License

This toolkit is provided for commercial use by licensed customers. See license agreement for terms and conditions.

---

*For detailed installation instructions, see `docs/INSTALL.md`*
