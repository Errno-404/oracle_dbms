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