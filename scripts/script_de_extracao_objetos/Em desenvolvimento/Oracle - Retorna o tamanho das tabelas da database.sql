/*
Lista todas as tabelas e suas metricas: tamanho do dados, tamanho do index, total de linhas  
*/
SELECT TB.OWNER
     , TB.TABLE_NAME
     , NVL(min(NUM_ROWS),0) NUM_ROWS
     , ROUND(sum(TB.DATA_KB),2) DATA_KB
     , ROUND(sum(IX.INDX_KB),2) INDX_KB
     , ROUND(sum(IX.INDX_KB + TB.DATA_KB ),2) RESERVED_KB
FROM (SELECT T.OWNER
           , T.TABLE_NAME
           , t.NUM_ROWS 
           , S.BYTES / 1024 AS DATA_KB       
      FROM ALL_TABLES T
      INNER JOIN DBA_SEGMENTS S ON T.TABLE_NAME = S.segment_name
      WHERE T.OWNER NOT IN('SYS','SYSTEM','SYSMAN')) TB 
INNER JOIN (SELECT I.OWNER
                 , I.INDEX_NAME
                 , I.TABLE_NAME
                 , S.BYTES / 1024 AS INDX_KB       
            FROM ALL_INDEXES I
            INNER JOIN DBA_SEGMENTS S ON I.INDEX_NAME = S.SEGMENT_NAME
            WHERE I.OWNER NOT IN('SYS','SYSTEM','SYSMAN')) IX ON IX.OWNER = TB.OWNER AND IX.TABLE_NAME = TB.TABLE_NAME
GROUP BY TB.OWNER, TB.TABLE_NAME