## [Original Source](https://github.com/duckdb/duckdb/discussions/13141){:target="_blank"}

connect to .mdb with pyodbc (in the past) or sqlalchemy (now), then query my data with something like this:

```
driver = "{Microsoft Access Driver (*.mdb, *.accdb)}"
accessFilePath = "C:\\path\\to\\myAccessDBfile.mdb" 
connstring=(r'DRIVER={{driver}}; DBQ={{accessFilePath}};')
connstring = connstring.replace("{{driver}}",driver)
connstring = connstring.replace("{{accessFilePath}}",accessFilePath)

from sqlalchemy.engine import URL
connection_url = URL.create("access+pyodbc", query={"odbc_connect": connstring})

from sqlalchemy import create_engine
conn = create_engine(connection_url)

import pandas
df1 = pandas.read_csv(...)
df2 = pandas.read_excel(...)

sql = "SELECT * FROM table3;"
df3 = pandas.read_sql(sql,conn)
```

mssql+pyodbc is for Microsoft SQL Server. You need to install [sqlalchemy-access](https://pypi.org/project/sqlalchemy-access/){:target="_blank"} and use access+pyodbc.


## [mdbread](https://github.com/gilesc/mdbread){:target="_blank"}

## <a href="https://pypi.org/project/mdb-parser/" target="_blank">MDBParser</a>
