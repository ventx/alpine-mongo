#!/bin/sh

[ "$1" = "mongod" ] || exec "$@" || exit $?

USERNAME=${MONGODB_USERNAME:-mongo}
PASSWORD=${MONGODB_PASSWORD:-mogno123}
DATABASE=${MONGODB_DBNAME:-admin}

if [ ! -z "$MONGODB_DBNAME" ]
then
    ROLE=${MONGODB_ROLE:-dbOwner}
else
    ROLE=${MONGODB_ROLE:-dbAdminAnyDatabase}
fi

# Start MongoDB service
/usr/bin/mongod --dbpath /data/db --nojournal &
while ! nc -vz localhost 27017; do sleep 1; done

# Create User
echo "Setting up ... : ${USERNAME} on ${DATABASE}"
USEREXIST=`mongo $DATABASE --eval "db.system.users.find({user:'${USERNAME}'}).count()"`
if ! [ ${USEREXIST} ];
 then
    CONFIG="{ user: '$USERNAME', pwd: '$PASSWORD', roles: [ { role: '$ROLE', db: '$DATABASE' } ] }"
    echo "Creating user ..."
    mongo $DATABASE --eval "db.createUser(${CONFIG})"
else 
    echo "User already exist skipping"
    echo "Todo: add functionality to update user/password"
fi

mongod --shutdown

cmd="$@"
exec /bin/sh -c mongod "$cmd"
