-- only first trigger implemented!!!


create or replace trigger CheckIfPlacesAvailableTrigger
    before insert
    on reservation
    for each row
declare
    trip_id int;
begin
    trip_id := :new.trip_id;


    if CHECKAVAILABLEPLACES(trip_id) = 0 then
        raise_application_error(-20003, 'There are no free places for that trip!');
    end if;
end;



create or replace procedure AddReservation8_0(trip_id trip.trip_id%TYPE, person_id person.person_id%TYPE)
as
    person_exists number;
    trip_exists   number;
    is_future     int;
begin

    -- checking if person exists
    select COUNT(*) into person_exists from person where person.person_id = AddReservation8_0.person_id;
    if person_exists = 0 then
        RAISE_APPLICATION_ERROR(-20002, 'Person with chosen ID not found.');
    end if;

    -- checking if trip exists
    select COUNT(*) into trip_exists from trip where trip.trip_id = AddReservation8_0.trip_id;
    if trip_exists = 0 then
        RAISE_APPLICATION_ERROR(-20002, 'Such trip does not exist!');
    end if;

    -- checking if trip is in the future
    select COUNT(*)
    into is_future
    from FUTURETRIPS ft
    where ft.trip_id = AddReservation8_0.TRIP_ID;

    if is_future = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'The trip for which given reservation was made has already started!');
    end if;

    insert into reservation (TRIP_ID, PERSON_ID, STATUS)
    values (AddReservation8_0.trip_id, AddReservation8_0.person_id, 'N');


end;

create or replace trigger StatusChangeControl
    before update of status
    on reservation
    for each row

declare
    pragma autonomous_transaction ;
    available_places int;
begin
    dbms_output.PUT_LINE('working');

    case
        when :old.status = 'C' then if :new.status = 'P' then
            raise_application_error(-20003, 'Error');
                                    end if;

                                    available_places := CHECKAVAILABLEPLACES(:old.TRIP_ID);
                                    if available_places = 0 then
                                        raise_application_error(-20003, 'dont');
                                    end if;

        when :old.status = 'P' then if :new.status = 'N' then
            raise_application_error(-20003, 'Error');
        end if;
        else null;
        end case;
end ;

create or replace procedure ModifyReservationStatus8_0(reservation_id number, status reservation.status%type)
as
    trip_id            int;
    old_status         reservation.status%type;
    reservation_exists number;
    is_future          number;
begin

    -- checking if reservation exists
    select COUNT(*)
    into reservation_exists
    from Reservations r
    where r.reservation_id = ModifyReservationStatus8_0.reservation_id;
    if reservation_exists = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'Reservation with chosen ID does not exist!');
    end if;

    -- checking if given new status is correct
    if ModifyReservationStatus8_0.status not in ('N', 'P', 'C') then
        raise_application_error(-20005, 'Wrong status!');
    end if;


    select r.trip_id
    into trip_id
    from Reservation r
    where r.RESERVATION_ID = ModifyReservationStatus8_0.reservation_id;

    -- checking if trip has already started
    select COUNT(*)
    into is_future
    from FUTURETRIPS ft
    where ft.trip_id = TRIP_ID;

    if is_future = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'The trip for which given reservation was made has already started!');
    end if;

    select r.status
    into old_status
    from reservation r
    where r.RESERVATION_ID = ModifyReservationStatus8_0.reservation_id;
    if ModifyReservationStatus8_0.status = old_status then
        raise_application_error(-20003, 'Given reservation already has such status!');
    end if;




    update RESERVATION
    set STATUS = ModifyReservationStatus8_0.status
    where RESERVATION_ID = ModifyReservationStatus8_0.reservation_id;


end ;


