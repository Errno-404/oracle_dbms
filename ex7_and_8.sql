-- ex 7 completed, half of ex 8 as well, both work

-- adding reservation to log trigger
create or replace trigger AddReservationLogTrigger
    after insert
    on reservation
    for each row
begin
    insert into log(reservation_id, log_date, status) VALUES (:new.reservation_id, current_date, :new.status);
end;

-- updating procedure
create or replace procedure AddReservation7_0(trip_id trip.trip_id%TYPE, person_id person.person_id%TYPE)
as
    person_exists  number;
    trip_exists    int;
    is_future      int;
    is_available   int;
    reservation_id int;
begin

    -- checking if person exists
    select COUNT(*) into person_exists from person where person.person_id = AddReservation7_0.person_id;
    if person_exists = 0 then
        RAISE_APPLICATION_ERROR(-20002, 'Person with chosen ID not found.');
    end if;

    -- checking if trip exists
    select count(*) into trip_exists from trip where trip.trip_id = AddReservation7_0.trip_id;
    if trip_exists = 0 then
        raise_application_error(-20003, 'Such trip does not exist!');
    end if;

    -- checking if trip is in the future
    select count(*) into is_future from FUTURETRIPS where FUTURETRIPS.TRIP_ID = AddReservation7_0.trip_id;
    if is_future = 0 then
        raise_application_error(-20003, 'The trip has already started!');
    end if;

    -- checking if trip is available (if there are no_places > 0)
    is_available := CHECKAVAILABLEPLACES(trip_id);
    if is_available = 0 then
        RAISE_APPLICATION_ERROR(-20003, 'Trip with chosen ID is not available.');
    end if;


    -- inserting data
    insert into reservation (TRIP_ID, PERSON_ID, STATUS)
    values (AddReservation7_0.trip_id, AddReservation7_0.person_id, 'N')
    returning reservation_id into AddReservation7_0.reservation_id;
end;




-- status change to log trigger
create or replace trigger ChangeStatusTrigger
    after update
    on Reservation
    for each row
begin
    insert into log(reservation_id, log_date, status)
    values (:new.reservation_id, current_date, :new.status);
end;


create or replace procedure ModifyReservationStatus7_0(reservation_id number, status reservation.status%type)
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
    where r.reservation_id = ModifyReservationStatus7_0.reservation_id;
    if reservation_exists = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'Reservation with chosen ID does not exist!');
    end if;

    -- checking if given new status is correct
    if ModifyReservationStatus7_0.status not in ('N', 'P', 'C') then
        raise_application_error(-20005, 'Wrong status!');
    end if;


    select r.trip_id into trip_id from Reservation r where r.RESERVATION_ID = ModifyReservationStatus7_0.reservation_id;

    -- checking if trip has already started
    select COUNT(*)
    into is_future
    from FUTURETRIPS ft
    where ft.trip_id = TRIP_ID;

    if is_future = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'The trip for which given reservation was made has already started!');
    end if;

    select r.status into old_status from reservation r where r.RESERVATION_ID = ModifyReservationStatus7_0.reservation_id;
    if ModifyReservationStatus7_0.status = old_status then
        raise_application_error(-20003, 'Given reservation already has such status!');
    end if;

    case
        when old_status = 'C'
            then if ModifyReservationStatus7_0.status <> 'N' then
                raise_application_error(-20003, 'Canceled reservation must be set to "N" (new) status first!');
                 end if;

                 if CheckAvailablePlaces(trip_id) = 0 then
                     raise_application_error(-20003, 'There are no free places left for the trip!');


                 end if;


        when old_status = 'P'
            then if (ModifyReservationStatus7_0.status <> 'C') then
                RAISE_APPLICATION_ERROR(-20006, 'P can only be changed to C status!');
            end if;

        else null;

        end case;


    update RESERVATION
    set STATUS = ModifyReservationStatus7_0.status
    where RESERVATION_ID = ModifyReservationStatus7_0.reservation_id;


end ;




-- trigger prevents from deleting anything from log
create or replace trigger ForbiddenLogDeletionTrigger
    before delete
    on log
    for each row
begin
    raise_application_error(-20003, 'Cannot remove reservation from Log');

end;

-- cannot remove reservation
create or replace trigger ForbiddenReservationDeletionTrigger
    before delete
    on reservation
    for each row
begin
    raise_application_error(-20003, 'Cannot remove reservation from Reservations!');
end;


-- ex 8.

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

-- ex8 b) skipped for now due to problem with mutating table which I couldn't solve in an easy way.

select * from reservation;
select * from AVAILABLETRIPSVIEW_1;
call ADDRESERVATION7_0(6, 8);
call ADDRESERVATION7_0(6, 8);
select * from log;

call ADDRESERVATION8_0(1, 2);
call AddReservation8_0(9, 10);
call ADDRESERVATION8_0(3, 10);

select * from TRIPPARTICIPANTs(6); select * from FUTURETRIPS;
select * from log;

call MODIFYRESERVATIONSTATUS7_0(11, 'N');
select * from trip where trip_id=6;

delete RESERVATION where RESERVATION_ID = 1;
delete log;

select * from log;

