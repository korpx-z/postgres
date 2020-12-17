set -e

export ANSI_YELLOW="\e[1;33m"
export ANSI_GREEN="\e[32m"
export ANSI_RESET="\e[0m"

echo -e "\n $ANSI_YELLOW *** testing docker run - postgres *** $ANSI_RESET \n"

echo -e "$ANSI_YELLOW Test docker run of Postgres: $ANSI_RESET"
docker run --name some-postgres -e POSTGRES_PASSWORD=mysecretpassword -p 5009:5432 -d quay.io/ibm/postgres:10
docker inspect some-postgres | grep 'Running'


echo -e "\n $ANSI_GREEN *** TEST COMPLETED SUCESSFULLY *** $ANSI_RESET \n"
