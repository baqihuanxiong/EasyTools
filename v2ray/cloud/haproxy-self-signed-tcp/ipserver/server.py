from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import argparse
import logging

logger = logging.getLogger()
logger.setLevel(logging.NOTSET)

parser = argparse.ArgumentParser(description="IP server")
parser.add_argument("-t", "--token", type=str, default="", help="API access token")
parser.add_argument("-p", "--port", type=int, default=9000, help="Server port")
args = parser.parse_args()

class Resquest(BaseHTTPRequestHandler):
    def do_POST(self):
        res = dict()
        try:
            client_ip = self.headers["X-Forwarded-For"].split(",")[0].strip() if self.headers["X-Forwarded-For"] else self.client_address[0]
            if args.token != "":
                if (req_len := int(self.headers['content-length'])) == 0:
                    res["error"] = "miss request body"
                else:
                    req = json.loads(self.rfile.read(req_len))
                    if req["token"] != args.token:
                        res["error"] = "access token incorrect"
                    else:
                        res["ip"] = client_ip
            else:
                res["ip"] = client_ip
        except Exception as e:
            res["error"] = str(e)
            logger.error(str(e))
        self.send_response(200)
        self.send_header("Content-type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(res).encode())


if __name__ == "__main__":
    server = HTTPServer(("", args.port), Resquest)
    logger.info("Starting server, listen at :{}".format(args.port))
    server.serve_forever()
