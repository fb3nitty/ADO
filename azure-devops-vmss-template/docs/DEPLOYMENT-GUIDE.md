
# Deployment Guide

This guide provides step-by-step instructions for deploying the Azure DevOps VMSS template.

## Prerequisites Checklist

Before starting the deployment, ensure you have:

- [ ] Azure subscription with Contributor access
- [ ] Azure DevOps organization with Project Administrator access
- [ ] Azure CLI installed and configured
- [ ] Git repository for storing the template files
- [ ] Personal Access Token with Agent Pools (read, manage) permissions

## Step-by-Step Deployment

### 1. Prepare Azure Environment

#### Create Resource Group
```bash
# Create resource group
az group create --name rg-devops-vmss --location "East US"

# Verify creation
az group show --name rg-devops-vmss
```

#### Create Service Principal (if not using Managed Identity)
```bash
# Create service principal
az ad sp create-for-rbac --name "sp-devops-vmss" --role contributor --scopes /subscriptions/{subscription-id}/resourceGroups/rg-devops-vmss

# Note the output for Azure DevOps service connection
```

### 2. Configure Azure DevOps

#### Create Service Connection
1. Navigate to Project Settings → Service connections
2. Click "New service connection"
3. Select "Azure Resource Manager"
4. Choose "Service principal (manual)"
5. Fill in the details from service principal creation
6. Name it `azure-service-connection`
7. Test and save

#### Create Variable Group
1. Navigate to Pipelines → Library
2. Click "Variable group"
3. Name it `vmss-secrets`
4. Add variables:
   - `admin-password`: Strong password for VM admin (mark as secret)
   - `devops-pat`: Your Personal Access Token (mark as secret)
5. Save the variable group

#### Create Environment
1. Navigate to Pipelines → Environments
2. Click "New environment"
3. Name it `production`
4. Select "None" for resource
5. Create environment

### 3. Prepare Template Files

#### Clone Repository
```bash
git clone <your-repository-url>
cd azure-devops-vmss-template
```

#### Update Configuration Files

**Update `variables/pipeline-vars.yml`:**
```yaml
variables:
  # Update these values for your environment
  azureServiceConnection: 'azure-service-connection'
  resourceGroupName: 'rg-devops-vmss'
  azureDevOpsUrl: 'https://dev.azure.com/your-organization'
  agentPoolName: 'Default'  # or your custom pool name
```

**Update `bicep/parameters.json`:**
```json
{
  "parameters": {
    "vmssName": {
      "value": "vmss-your-agents"
    },
    "agentPoolName": {
      "value": "Default"
    }
  }
}
```

### 4. Create Azure DevOps Pipeline

#### Method 1: Using Azure DevOps UI
1. Navigate to Pipelines → Pipelines
2. Click "New pipeline"
3. Select your repository source
4. Choose "Existing Azure Pipelines YAML file"
5. Select `azure-pipelines.yml`
6. Review and run

#### Method 2: Using Azure CLI
```bash
# Create pipeline using Azure CLI
az pipelines create --name "VMSS-Deployment" --repository <repo-url> --branch main --yml-path azure-pipelines.yml
```

### 5. Deploy Infrastructure

#### Run the Pipeline
1. Navigate to your pipeline
2. Click "Run pipeline"
3. Monitor the deployment progress
4. Check for any errors in the logs

#### Verify Deployment
```bash
# Check resource group resources
az resource list --resource-group rg-devops-vmss --output table

# Check VMSS status
az vmss show --resource-group rg-devops-vmss --name vmss-devops-agents --output table

# Check VMSS instances
az vmss list-instances --resource-group rg-devops-vmss --name vmss-devops-agents --output table
```

### 6. Verify Agent Registration

#### Check Azure DevOps Agent Pool
1. Navigate to Organization Settings → Agent pools
2. Select your agent pool (Default or custom)
3. Verify agents appear as "Online"
4. Check agent capabilities include .NET Core

#### Test Build Agent
1. Create a simple test pipeline:
```yaml
trigger: none

pool:
  name: 'Default'  # Your agent pool name

steps:
- task: DotNetCoreCLI@2
  displayName: 'Test .NET Installation'
  inputs:
    command: 'custom'
    custom: '--version'

- script: |
    echo "Agent Name: $(Agent.Name)"
    echo "Agent OS: $(Agent.OS)"
    echo "Build Number: $(Build.BuildNumber)"
  displayName: 'Display Agent Info'
```

2. Run the test pipeline
3. Verify it runs successfully on your new agents

## Post-Deployment Configuration

### 1. Configure Auto-scaling (Optional)

If you need custom auto-scaling rules:

```bash
# Update auto-scale settings
az monitor autoscale rule create \
  --resource-group rg-devops-vmss \
  --autoscale-name vmss-devops-agents-autoscale \
  --condition "Percentage CPU > 80 avg 5m" \
  --scale out 2
```

### 2. Set Up Monitoring

#### Enable VM Insights
```bash
# Enable VM insights for the scale set
az vm extension set \
  --resource-group rg-devops-vmss \
  --vmss-name vmss-devops-agents \
  --name MicrosoftMonitoringAgent \
  --publisher Microsoft.EnterpriseCloud.Monitoring
```

#### Create Alerts
```bash
# Create CPU alert
az monitor metrics alert create \
  --name "High CPU Usage" \
  --resource-group rg-devops-vmss \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-devops-vmss/providers/Microsoft.Compute/virtualMachineScaleSets/vmss-devops-agents \
  --condition "avg Percentage CPU > 85" \
  --description "Alert when CPU usage is high"
```

### 3. Security Hardening

#### Update NSG Rules (if needed)
```bash
# Add custom NSG rule
az network nsg rule create \
  --resource-group rg-devops-vmss \
  --nsg-name nsg-devops-agents \
  --name AllowCustomApp \
  --priority 1100 \
  --source-address-prefixes VirtualNetwork \
  --destination-port-ranges 8080 \
  --access Allow \
  --protocol Tcp
```

#### Enable Just-In-Time Access
```bash
# Enable JIT access (requires Azure Security Center)
az security jit-policy create \
  --resource-group rg-devops-vmss \
  --name vmss-devops-agents \
  --virtual-machines vmss-devops-agents
```

## Troubleshooting Deployment Issues

### Common Deployment Failures

#### 1. Insufficient Permissions
**Error**: `Authorization failed`
**Solution**: 
- Verify service principal has Contributor role
- Check resource group permissions
- Ensure subscription access

#### 2. Quota Exceeded
**Error**: `Operation could not be completed as it results in exceeding approved quota`
**Solution**:
```bash
# Check current usage
az vm list-usage --location "East US" --output table

# Request quota increase if needed
```

#### 3. Agent Registration Fails
**Error**: Agents don't appear in pool
**Solution**:
- Check PAT permissions
- Verify Azure DevOps URL
- Review VM extension logs:
```bash
az vmss extension show \
  --resource-group rg-devops-vmss \
  --vmss-name vmss-devops-agents \
  --name InstallDevOpsAgent
```

#### 4. Network Connectivity Issues
**Error**: VMs can't reach Azure DevOps
**Solution**:
- Check NSG rules
- Verify subnet configuration
- Test connectivity from VM:
```powershell
# From VM
Test-NetConnection dev.azure.com -Port 443
```

### Debugging Commands

#### Check Deployment Status
```bash
# List deployments
az deployment group list --resource-group rg-devops-vmss --output table

# Get deployment details
az deployment group show --resource-group rg-devops-vmss --name <deployment-name>
```

#### Check VM Extension Status
```bash
# List extensions
az vmss extension list --resource-group rg-devops-vmss --vmss-name vmss-devops-agents

# Get extension output
az vmss extension show \
  --resource-group rg-devops-vmss \
  --vmss-name vmss-devops-agents \
  --name InstallDevOpsAgent \
  --instance-id 0
```

#### Access VM for Debugging
```bash
# Get public IP
az network public-ip show --resource-group rg-devops-vmss --name vmss-devops-agents-pip

# RDP to specific instance (if needed)
az vmss list-instance-connection-info \
  --resource-group rg-devops-vmss \
  --name vmss-devops-agents
```

## Cleanup

To remove all resources:

```bash
# Delete resource group (removes all resources)
az group delete --name rg-devops-vmss --yes --no-wait

# Remove service principal (if created)
az ad sp delete --id <service-principal-id>
```

## Next Steps

After successful deployment:

1. **Configure Build Pipelines**: Update existing pipelines to use the new agent pool
2. **Set Up Monitoring**: Configure alerts and monitoring dashboards
3. **Implement Backup**: Set up backup policies for critical data
4. **Security Review**: Conduct security assessment and implement additional controls
5. **Cost Optimization**: Review and optimize resource sizing and auto-scaling rules

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Review Azure Activity Log for deployment errors
3. Check Azure DevOps pipeline logs
4. Review VM extension logs on the instances
5. Open an issue in the repository with detailed error information
