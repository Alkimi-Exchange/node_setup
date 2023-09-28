import subprocess

# Command to run
command = "./nms_web_server > nms_web_server.log 2>&1 &"

# Run the command using subprocess
try:
    subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    print("nms_web_server started successfully.")
except Exception as e:
    print(f"Error starting nms_web_server: {str(e)}")
