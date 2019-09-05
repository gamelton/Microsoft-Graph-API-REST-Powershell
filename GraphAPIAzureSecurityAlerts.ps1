$fromdate=(Get-Date).AddDays(-7).ToString("yyyy-MM-dd")
$AppId = 'CLIENTID'
$AppSecret = 'APPPASSWORD'
$Scope = "https://graph.microsoft.com/.default"
$TenantName = "TENANTID"
$Url = "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token"

Add-Type -AssemblyName System.Web

$Body = @{
    client_id = $AppId
	client_secret = $AppSecret
	scope = $Scope
	grant_type = 'client_credentials'
}
$PostSplat = @{
    ContentType = 'application/x-www-form-urlencoded'
    Method = 'POST'
    Body = $Body
    Uri = $Url
}
$Request = Invoke-RestMethod @PostSplat
$Header = @{
    Authorization = "$($Request.token_type) $($Request.access_token)"
}

$Uri = "https://graph.microsoft.com/v1.0/security/alerts"
$SecurityAlertsRequest = Invoke-RestMethod -Uri $Uri -Headers $Header -Method Get -ContentType "application/json"
$SecurityAlerts = $SecurityAlertsRequest.Value | select @{Name='userPrincipalName';Expression={$_.userStates.userPrincipalName}}, title, description, category, @{Name='logonIp';Expression={$_.userStates.logonIp}}, createdDateTime, @{Name='logonLocation';Expression={$_.userStates.logonLocation}}
$SecurityAlertsLastWeek = $SecurityAlerts | where {[datetime]$_.createdDateTime -ge $(Get-Date).AddDays(-7)} 
if($SecurityAlertsLastWeek){
$SecurityAlertsLastWeek | ConvertTo-Html -body "<H2>Security alerts in Azure AD</H2>" | Out-File 'SECURITYALERTS\PATH.HTML'
}

$Uri = "https://graph.microsoft.com/v1.0/auditLogs/signIns?&`$filter=status/errorCode eq 50126 and createdDateTime ge $fromdate"
$AuditLogsRequest = Invoke-RestMethod -Uri $Uri -Headers $Header -Method Get -ContentType "application/json"
$AuditLogs = $AuditLogsRequest.value | select userPrincipalName, appDisplayName, ipAddress, @{Name='errorCode';Expression={$_.status.errorCode}},@{Name='failureReason';Expression={$_.status.failureReason}}, createdDateTime, @{Name='operatingSystem';Expression={$_.deviceDetail.operatingSystem}}, @{Name='city';Expression={$_.location.city}},  @{Name='countryOrRegion';Expression={$_.location.countryOrRegion}}
if($AuditLogs){
$AuditLogs | ConvertTo-Html -body "<H2>Failed logins in Azure AD</H2>" | Out-File 'FAILEDLOGIN\PATH.HTML'
}

$Uri = "https://graph.microsoft.com/v1.0/auditLogs/signIns?&`$filter=riskState eq 'atRisk' and createdDateTime ge $fromdate"
$AuditLogsAtRiskRequest = Invoke-RestMethod -Uri $Uri -Headers $Header -Method Get -ContentType "application/json"
$AuditLogsAtRisk = $AuditLogsAtRiskRequest.value | select userPrincipalName, appDisplayName, ipAddress, riskState, @{Name='riskEventTypes';Expression={[string]::join(“;”, ($_.riskEventTypes))}}, createdDateTime, @{Name='operatingSystem';Expression={$_.deviceDetail.operatingSystem}}, @{Name='city';Expression={$_.location.city}},  @{Name='countryOrRegion';Expression={$_.location.countryOrRegion}}
if($AuditLogsAtRisk){
$AuditLogsAtRisk | ConvertTo-Html -body "<H2>Logins with at risk state in Azure AD</H2>" | Out-File 'LOGINWITHATRISK\PATH.HTML'
}

if($SecurityAlertsLastWeek -or $AuditLogs -or $AuditLogsAtRisk){
if($SecurityAlertsLastWeek){
$FHSecurityAlertsLastWeek = [System.IO.File]::ReadAllText('SECURITYALERTS\PATH.HTML')
}
if($AuditLogs){
$FHAuditLogs = [System.IO.File]::ReadAllText('FAILEDLOGIN\PATH.HTML')
}
if($AuditLogsAtRisk){
$FHAuditLogsAtRisk = [System.IO.File]::ReadAllText('LOGINWITHATRISK\PATH.HTML')
}
$EmailBody = "<p>Below are Azure AD sign-in reports over last week starting from $fromdate.</p>
$FHSecurityAlertsLastWeek
$FHAuditLogs
$FHAuditLogsAtRisk"
Send-MailMessage  –From "FROMEMAIL@ADDRESS" –To "TOEMAIL@ADDRESS" –Subject "Azure AD sign-in report $(Get-Date -Format "yyyy-MM-dd")" -Body $EmailBody -BodyAsHtml –SmtpServer "MAIL.SERVER"
Remove-Item ''SECURITYALERTS\PATH.HTML'
Remove-Item 'FAILEDLOGIN\PATH.HTML'
Remove-Item 'LOGINWITHATRISK\PATH.HTML'
}
