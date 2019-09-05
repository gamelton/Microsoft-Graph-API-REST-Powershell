# Microsoft-Graph-API-REST-Powershell
Query Graph API with Powershell for security alerts

Get Azure Active Directory failed sign-ins and security alerts from Graph API.
Three querries. You could change them and specific details or add new.
1. Query for [security alerts](https://docs.microsoft.com/en-us/graph/api/alert-list) over last week.
1. Query for [incorrect login or password sign-ins](https://docs.microsoft.com/en-us/graph/api/signin-list) over last week. Filter for specifit Event ID of **50126** that's `Invalid username or password`.
1. Query for sign-ins with `atRisk` state over last week. This might include same events as first query.
1. Put each query's result into html file. The path is absolute.
1. Combine files and send them via email.
1. This script is run as Scheduled Job once a week.

Requirements:
1. Azure Active Directory premium 1 (P1) license
1. Application has specific API permission

Preparation:
1. Get Tenant (Authority) ID that is Directory ID from Azure AD
1. Register application for you Azure AD
   1. Get Application (Client) ID from Application properties
   1. Make sure to grant API permission to the application
      1. AuditLog.Read.All 
      1. Directory.Read.All
      1. SecurityEvents.Read.All
   
   Note: You would need to press grant admin consent button to apply for the organization.
1. Edit the script and supply your
   1. `TENANTID` for Tenant (Authority)
   1. `CLIENTID` and `APPPASSWORD` for Application (Client) secret
   1. `AZUREADUSERLOGIN` and `AZUREADUSERPASSWORD` for Azure AD User with correct role
   1. `SECURITYALERTS\PATH.HTML`, `FAILEDLOGIN\PATH.HTML` and `LOGINWITHATRISK\PATH.HTML`for HTML files.
   1. `FROMEMAIL@ADDRESS`, `TOEMAIL@ADDRESS` and `MAIL.SERVER` to send generated email
