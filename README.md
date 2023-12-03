# lpu.mca.project.webjea

Remote Server Administration Dashboard

To run the project:

1. Install IIS, 
2. Copy source and scripts folders under C drive.
3. Copy webjea under C:\inetpub\wwwroot
4. Add Bindings for Default Web Site:
	Type: https
	IP Addresses: All Unassigned
	port: 443
	Host name: FQDN of your server joined to domain
	Check the Require Server Name Indication
	Select SSL Certificate
	Add App Pool
