import os, json
from typing import Optional, Union, Dict
from urllib.parse import quote, urlencode, parse_qsl
from json import JSONDecodeError

'''
This is a common Script for creating Airflow Connections and doing the necessary URL encoding.
Any field if not required can be left undeclared.
An example of the environment variables to be created to generate the connection string.
CONN_ID = 'postgres_uri'
CONN_TYPE = 'db+postgresql'
LOGIN = 'username'
PASSWORD = 'password'
HOST = 'localhost'
PORT = '5432'
SCHEMA = 'db'
EXTRA = {'key1':'value1','key2':'value2'}
It generates a file named as `CONN_ID` with the connection string as the content #L129.
'''

CONN_ID = os.getenv('CONN_ID')
CONN_TYPE = os.getenv('CONN_TYPE')
LOGIN = os.getenv('LOGIN')
PASSWORD = os.getenv('PASSWORD')
HOST = os.getenv('HOST')
PORT = os.getenv('PORT')
SCHEMA = os.getenv('SCHEMA')
EXTRA = os.getenv('EXTRA')


class Connection( ):
    EXTRA_KEY = '__extra__'

    def __init__(
        self,
        conn_type: Optional[str] = None,
        login: Optional[str] = None,
        password: Optional[str] = None,
        host: Optional[str] = None,
        port: Optional[int] = None,
        schema: Optional[str] = None,
        extra: Optional[Union[str, dict]] = None,
    ):
        super().__init__()
        if extra and not isinstance(extra, str):
            extra = json.dumps(extra)
        self.conn_type = conn_type
        self.host = host
        self.login = login
        self.password = password
        self.schema = schema
        self.port = port
        if extra:
            self.extra = extra.replace('\'','"')
        else:
            self.extra = extra

    def get_uri(self) -> str:
        """Return connection in URI format"""
        if '_' in self.conn_type:
            self.log.warning(
                f"Connection schemes (type: {str(self.conn_type)}) "
                f"shall not contain '_' according to RFC3986."
            )

        uri = f"{str(self.conn_type).lower().replace('_', '-')}://"

        authority_block = ''
        if self.login is not None:
            authority_block += quote(self.login, safe='')

        if self.password is not None:
            authority_block += ':' + quote(self.password, safe='')

        if authority_block > '':
            authority_block += '@'

            uri += authority_block

        host_block = ''
        if self.host:
            host_block += quote(self.host, safe='')

        if self.port:
            if host_block > '':
                host_block += f':{self.port}'
            else:
                host_block += f'@:{self.port}'

        if self.schema:
            host_block += f"/{quote(self.schema, safe='')}"

        uri += host_block

        if self.extra:
            try:
                query: Optional[str] = urlencode(self.extra_dejson)
            except TypeError:
                query = None
            if query and self.extra_dejson == dict(parse_qsl(query, keep_blank_values=True)):
                uri += '?' + query
            else:
                uri += '?' + urlencode({self.EXTRA_KEY: self.extra})

        return uri

    @property
    def extra_dejson(self) -> Dict:
        """Returns the extra property by deserializing json."""
        obj = {}
        if self.extra:
            try:
                obj = json.loads(self.extra)

            except JSONDecodeError:
                self.log.exception("Failed parsing the json for conn_id %s", self.conn_id)

        return obj

c = Connection(
    host=HOST,
    login=LOGIN,
    password=PASSWORD,
    schema=SCHEMA,
    conn_type=CONN_TYPE,
    port=PORT,
    extra=EXTRA
)
with open(f'./helperChart/secrets/{CONN_ID}','w') as fp:
    fp.write(c.get_uri())