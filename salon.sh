#!/bin/bash
# I went "off script" for this project and used a dynamic array system for service selection instead of a hard-coded case/esac which would eventually fail if we ever had to change the offered services.
# Also, I dislike checking for arguments at the start of the function, if all it does is print a string that could just be printed at-location when necessary.
PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ Micah's Salon & Bar & Grill ~~~~~\n\nOur currently offered services are listed below. Select one by entering its number.\n"

SERVICE_MENU() {
AVAILABLE_SERVICES=$($PSQL "SELECT service_id,name FROM services ORDER BY service_id")
declare -A A_S_ARRAY # declare –a array_a=() OR declare –a array
while read SERVICE_ID BAR SERVICE_NAME
do
	echo "$SERVICE_ID) $SERVICE_NAME"
	A_S_ARRAY[$SERVICE_ID]="$SERVICE_NAME"
done < <(echo "$AVAILABLE_SERVICES") # why is <() required instead of just the single < like with all other redirection? Furthermore, this "substitution" is a necessary alternative to `echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR SERVICE_NAME`, because in that case, ASSIGNING TO THE ARRAY OCCURS ONLY IN THE SUBSHELL AND IT DOESN'T ACTUALLY HAPPEN EVEN IF WE DECLARED THE ARRAY OUTSIDE OF IT
read SERVICE_ID_SELECTED

if [[ -z ${A_S_ARRAY[$SERVICE_ID_SELECTED]} ]]
then
	echo -e "\nI could not find that service. What would you like today?"	# Would have rather "That service, number $SERVICE_ID_SELECTED, is not available.""
	SERVICE_MENU	# In bash, you can restart a function by calling itself
else # Else is required, or else the script would continue from this point after a bad input and then a good input
	echo -e "\nEnter your phone number as xxx-xxx-xxxx for identification."
	read CUSTOMER_PHONE
	CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
	# read CUSTOMER_ID BAR CUSTOMER_NAME < <(echo "$CUSTOMER_INFO") # used before I realized collecting both variables is pointless if it's a new customer. But, this statement does work as you imagine
	if [[ -z $CUSTOMER_NAME ]]
	then
		echo -e "\nA new customer! Enter your name, please!"
		read CUSTOMER_NAME
		INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name, phone) VALUES('$CUSTOMER_NAME', '$CUSTOMER_PHONE')")
	fi

	CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
	echo -e "\nWhat time would you like your ${A_S_ARRAY[$SERVICE_ID_SELECTED]}, $(echo $CUSTOMER_NAME| sed -E 's/ *$|^ *//g')?"
	read SERVICE_TIME
	INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id,time) VALUES($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
	echo -e "\nI have put you down for a ${A_S_ARRAY[$SERVICE_ID_SELECTED]} at $SERVICE_TIME, $(echo $CUSTOMER_NAME| sed -E 's/ *$|^ *//g')."	# Personally would rather "You have been put down for a service"
fi
}

SERVICE_MENU