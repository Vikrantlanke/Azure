# Azure Container Registry Retention Policy

To maintain a usage of Azure container registry, we should periodically delete stale image data. While some container images deployed into production may require longer-term storage, perhaps others can typically be deleted more quickly. For example, in an automated build and test scenario, our registry can quickly fill with images that might never be deployed and can be purged shortly after completing the build and test pass.

Because we can delete image data in several different ways, it's important to understand how each delete operation affects storage usage. Below are the methods for deleting image:

1. Delete a [repository](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-delete#delete-repository): Deletes all images and all unique layers within the repository.
2. Delete by [tag](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-delete#delete-by-tag): Deletes an image, the tag, all unique layers referenced by the image, and all other tags associated with the image.
3. Delete by [manifest digest](https://docs.microsoft.com/en-us/azure/container-registry/container-registry-delete#delete-by-manifest-digest): Deletes an image, all unique layers referenced by the image, and all tags associated with the image.

Writing a custom script for cleaning up the registry gives more control over what we want to delete it.
The given script in the repository executes from Azure DevOps Pipeline after a specific time on below conditions -

a. Delete Feature branch images older than 15 Days

b. Delete Staging branch images older than 30 Days

c. Delete Master branch (Production) images older than 45 Days

d. Delete all untagged images 

You can modify this script as per the requirement. It helps a lot to keep costing in control for Azure Container Registry and keep a registry clean.

Steps to follow: 

1) Copy entire directory to Azure repository
2) Do the necessary changes in script and Azure DevOps Pipeline Template
```bash
# Modify for your Registry Name in acr-cleaner.sh file.
REGISTRY="<Registry name>"
```
```bash
# Modify values in acr-clener-pipeline.yaml file.
# If you have custom agent for job execution no then remove pool section
stages:
  - stage: Pipeline
    pool:
      name: #if you have custom agent pool for execution
      
# Add your Azure subscription name      
 inputs:
   azureSubscription: # Azure Subscription Name  
```