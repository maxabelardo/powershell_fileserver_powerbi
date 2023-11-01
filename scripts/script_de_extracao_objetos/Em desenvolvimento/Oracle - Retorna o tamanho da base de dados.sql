— Tamanho do banco

select sum(bytes) / 1024 / 1024 / 1024 tamanho_GB from dba_segments;

— ou

select sum(bytes) /1073741824  TAMANHO_GB from dba_segments;

— Tamanho por Tablespace

select tablespace_name, sum(bytes) / 1024 / 1024 / 1024 tamanho_GB from dba_segments group by tablespace_name;