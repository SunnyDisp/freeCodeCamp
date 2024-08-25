#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"

MAIN_MENU() {

  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  echo "Welcome to My Salon, how may I help you?"
  SERVICES_MENU
}

SERVICES_MENU() {

  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # get available services
  AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")

  # display available services
  echo -e "\nHere are the services we offer:"
  AVAILABLE_SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
  echo "$AVAILABLE_SERVICES" | while IFS="|" read -r SERVICE_ID NAME
  do
    SERVICE_ID=$(echo $SERVICE_ID | sed 's/ //g')
    NAME=$(echo $NAME | sed 's/^ *| *$//g')
    echo "$SERVICE_ID) $NAME"
  done

  # ask for service to get
  echo -e "\nWhich one would you like to avail?"
  read SERVICE_ID_SELECTED

  # if input is a valid service ID
  SERVICE_EXISTS=$($PSQL "SELECT service_id FROM services WHERE service_id = '$SERVICE_ID_SELECTED'")

  if [[ -n $SERVICE_EXISTS ]]
  then 
    SET_APPOINTMENT $SERVICE_ID_SELECTED
  else
    SERVICES_MENU "I could not find that service. What would you like today?"
  fi
}

SET_APPOINTMENT() {
  SERVICE_ID=$1

  # get phone number
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  # if customer doesn't exist
  if [[ -z $CUSTOMER_NAME ]]
  then
    # get new customer name
    echo -e "\nWhat's your name?"
    read CUSTOMER_NAME

    # insert new customer
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
  else
    CUSTOMER_NAME=$(echo $CUSTOMER_NAME | sed 's/ *$//')
  fi

  # get time of appointment
  echo -e "\nWhat time would you like your appointment, $CUSTOMER_NAME?"
  read SERVICE_TIME

  # get customer_id
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")

  # insert appointment
  INSERT_APPOINTMENT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $SERVICE_ID, '$SERVICE_TIME')")

  if [[ $INSERT_APPOINTMENT == "INSERT 0 1" ]]
  then
    SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID")
    SERVICE_NAME=$(echo $SERVICE_NAME | sed 's/ *$//')
    echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
  else
    echo -e "\nThere was an error scheduling your appointment."
  fi
}

EXIT() {
  echo -e "\nThank you for stopping in.\n"
}

MAIN_MENU
