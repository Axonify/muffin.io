from google.appengine.api import memcache
import json
from apps import DEBUG

#
# Decorators
#

def memcached(age):
    """
    Note that a decorator with arguments must return the real decorator that,
    in turn, decorates the function. For example:
        @decorate("extra")
        def function(a, b):
        ...
    is functionally equivallent to:
        function = decorate("extra")(function)
    """
    def inner_memcached(func):
        """ A decorator that implements the memcache pattern """
        def new_func(requestHandler, *args, **kwargs):
            result = memcache.get(requestHandler.request.url)
            if result is None or age == 0 or DEBUG:
                # Use compact JSON encoding
                result = json.dumps(func(requestHandler, *args, **kwargs), separators=(',',':'))
                memcache.set(requestHandler.request.url, result, age)
            requestHandler.response.headers["Content-Type"] = "application/json"
            requestHandler.response.out.write(result)
        return new_func
    return inner_memcached

def as_json(func):
    """Dump in JSON format"""
    def new_func(requestHandler, *args, **kwargs):
        # Use compact JSON encoding
        result = json.dumps(func(requestHandler, *args, **kwargs), separators=(',',':'))
        requestHandler.response.headers["Content-Type"] = "application/json"
        requestHandler.response.out.write(result)
    return new_func
