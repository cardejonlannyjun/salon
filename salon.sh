#! /bin/bash

printf '\n~~~~~ MY SALON ~~~~~\n\n'
printf 'Welcome to My Salon, how can I help you?\n\n'

while true; do
  SERVICE_LIST=$(psql --username=freecodecamp --dbname=salon --no-align --tuples-only -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id")
  printf '%s\n' "$SERVICE_LIST"
  read SERVICE_ID_SELECTED

  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=$(psql --username=freecodecamp --dbname=salon --no-align --tuples-only -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
  else
    SERVICE_NAME=
  fi
  if [[ -n "$SERVICE_NAME" ]]; then
    break
  fi

  printf '\nI could not find that service. What would you like today?\n'
done

printf "\nWhat's your phone number?\n"
read CUSTOMER_PHONE

CUSTOMER_ID=$(psql --username=freecodecamp --dbname=salon --set=ON_ERROR_STOP=1 --no-align --tuples-only -v phone="$CUSTOMER_PHONE" <<'SQL'
SELECT customer_id FROM customers WHERE phone = :'phone';
SQL
)

if [[ -z "$CUSTOMER_ID" ]]; then
  printf "\nI don't have a record for that phone number, what's your name?\n"
  read CUSTOMER_NAME
  CUSTOMER_ID=$(psql --username=freecodecamp --dbname=salon --set=ON_ERROR_STOP=1 --quiet --no-align --tuples-only -v phone="$CUSTOMER_PHONE" -v name="$CUSTOMER_NAME" <<'SQL'
INSERT INTO customers (phone, name) VALUES (:'phone', :'name') RETURNING customer_id;
SQL
)
else
  CUSTOMER_NAME=$(psql --username=freecodecamp --dbname=salon --set=ON_ERROR_STOP=1 --no-align --tuples-only -v customer_id="$CUSTOMER_ID" <<'SQL'
SELECT name FROM customers WHERE customer_id = :'customer_id';
SQL
)
fi

printf '\nWhat time would you like your %s, %s?\n' "$SERVICE_NAME" "$CUSTOMER_NAME"
read SERVICE_TIME

psql --username=freecodecamp --dbname=salon --set=ON_ERROR_STOP=1 --quiet --no-align --tuples-only -v customer_id="$CUSTOMER_ID" -v service_id="$SERVICE_ID_SELECTED" -v service_time="$SERVICE_TIME" <<'SQL'
INSERT INTO appointments (customer_id, service_id, time)
VALUES (:'customer_id', :'service_id', :'service_time');
SQL

printf '\nI have put you down for a %s at %s, %s.\n' "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"
