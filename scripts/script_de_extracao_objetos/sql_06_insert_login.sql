SELECT L.name     
        , L.loginname
        , L.isntname 
        , L.sysadmin
        , L.securityadmin
        , L.serveradmin
        , L.setupadmin
        , L.processadmin
        , L.diskadmin
        , L.dbcreator
        , L.bulkadmin
        , L.[sid]
FROM [sys].syslogins AS L