APP_DIR=/app
PIPE_DIR=/app/docker_pipes
PIPE_FILE=/app/docker_pipes/project_app_pipe
if [ ! -d "$APP_DIR" ];
then
        echo "APP DIR Created"
        sudo mkdir /app
fi
if [ -d "$PIPE_DIR" ] ;
then
        if [ -e "$PIPE_FILE" ] ;
        then
                echo "Pipe Exists"
        else
                sudo mkfifo $PIPE_FILE
                echo "PIPE Created"
        fi
else
        sudo mkdir /app/docker_pipes
        sudo mkfifo $PIPE_FILE
        echo "PIPE Created"
fi

while true;
        do eval "$(cat $PIPE_FILE)" ;
done
