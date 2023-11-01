	select 
	  path,
	  group_number GROUP#,
	  disk_number DISK#,
	  round(OS_MB/1024,2) OS_GB,
	  round(TOTAL_MB/1024,2) TOTAL_GB,
	  round(FREE_MB/1024/2) FREE_GB,
	  NAME,
	  FAILGROUP,
	  header_status,
	  mode_status,
	  LABEL
	from V$ASM_DISK
	ORDER BY group#, disk#,name;