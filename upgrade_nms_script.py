import http.server
import platform
import shutil
import socketserver
import os
import subprocess
import json
import time 
import threading
import multiprocessing
from http.server import BaseHTTPRequestHandler


def send_response(handler, status_code, message):
    # Send the HTTP response status code
    handler.send_response(status_code)

    # End the HTTP headers
    handler.end_headers()

    # Create a response body as a dictionary
    response_body = {
        'success': True if status_code == 201 else False,
        'message': message
    }

    # Convert the response body to a JSON string
    response_json = json.dumps(response_body)

    # Write the JSON response to the client
    handler.wfile.write(bytes(response_json, 'utf-8'))


def command_run(command):
    try:
        # Execute the download command using subprocess
        result = subprocess.run(command, shell=True, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

        # Check the return code to see if the command was successful
        if result.returncode != 0:
            print(f"Command execution failed: {result.stderr}")
        else:
            print(f"Command execution successfully: {command}")

    except Exception as e:
        print(f"Error during command execution: {str(e)}")



def upgrade_nms(handler, project):
    try:
        # Start the subprocess in the background
        process = subprocess.Popen("/home/ubuntu/node_setup/upgrade_nms.sh", shell=True)
        print(f"this is process {process}")
        # Respond to the client immediately
        send_response(handler, 201, "Upgrade process started in the background.")
    except Exception as e:
        print(f"Error during command execution: {str(e)}")




class MyHandler(http.server.SimpleHTTPRequestHandler):
    
    def send_error_response(self, status_code, message):
        self.send_response(status_code)
        self.end_headers()
        self.wfile.write(bytes(message, 'utf-8'))

    def do_POST(self):
        content_length = int(self.headers['Content-Length'])
        data = self.rfile.read(content_length)
        project = data.decode('utf-8').split("=")[-1]

        if self.path == "/upgrade_nms":
            upgrade_nms(self, project)

        else:
            self.send_error_response(404, "Invalid path")

def nms_project_server(host, port):
    # Create the server with the custom handler
    with socketserver.TCPServer((host, port), MyHandler) as httpd:
        print(f"Serving at http://{host}:{port}")

        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            pass

    print("Server stopped.")


if __name__ == "__main__":
    host = 'localhost'
    port = 8002
    nms_project_server(host, port)  # Start the NMS project server
