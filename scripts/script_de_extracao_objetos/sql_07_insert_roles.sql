select g.name as [RoleNome]
        , g.sid  as [RoleSid]
        , u.name as [LoginName]
        , u.sid  as [LoginSid]
from sys.database_principals u
    ,sys.database_principals g
    ,sys.database_role_members m 
where g.principal_id = m.role_principal_id 
    and u.principal_id = m.member_principal_id