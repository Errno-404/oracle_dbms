-- adding reservation to log trigger
create or replace trigger UpdateTripAvailablePlaces
    after insert
    on reservation
    for each row
declare
    old_available int;
begin
    old_available := CHECKAVAILABLEPLACES9_0(:new.trip_id);


    update TRIP
    set NO_AVAILABLE_PLACES = old_available - 1
    where trip_id = :new.trip_id;

end;

-- updating procedure
create or replace procedure AddReservation10_0(trip_id trip.trip_id%TYPE, person_id person.person_id%TYPE)
as
    person_exists  number;
    trip_exists    int;
    is_future      int;
    is_available   int;
    reservation_id int;
begin

    -- checking if person exists
    select COUNT(*) into person_exists from person where person.person_id = AddReservation10_0.person_id;
    if person_exists = 0 then
        RAISE_APPLICATION_ERROR(-20002, 'Person with chosen ID not found.');
    end if;

    -- checking if trip exists
    select count(*) into trip_exists from trip where trip.trip_id = AddReservation10_0.trip_id;
    if trip_exists = 0 then
        raise_application_error(-20003, 'Such trip does not exist!');
    end if;

    -- checking if trip is in the future
    select count(*) into is_future from FUTURETRIPS where FUTURETRIPS.TRIP_ID = AddReservation10_0.trip_id;
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
    values (AddReservation10_0.trip_id, AddReservation10_0.person_id, 'N')
    returning reservation_id into AddReservation10_0.reservation_id;
end;



-- status change to log trigger
create or replace trigger ManageAvailableTrigger
    after update
    on Reservation
    for each row
declare
    old_available int;
begin
    if :old.status = 'C' and :new.status = 'N' then
        select NO_AVAILABLE_PLACES into old_available from TRIP where TRIP.TRIP_ID = :old.trip_id;
        update TRIP
        set trip.NO_AVAILABLE_PLACES = old_available - 1
        where trip_id = :old.trip_id;
    end if;

    if (:old.status = 'P' or :old.status = 'N') and :new.status = 'C' then
        select NO_AVAILABLE_PLACES into old_available from TRIP where TRIP.TRIP_ID = :old.trip_id;
        update TRIP
        set trip.NO_AVAILABLE_PLACES = old_available + 1
        where trip_id = :old.trip_id;
    end if;

end;


create or replace procedure ModifyReservationStatus10_0(reservation_id number, status reservation.status%type)
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
    where r.reservation_id = ModifyReservationStatus10_0.reservation_id;
    if reservation_exists = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'Reservation with chosen ID does not exist!');
    end if;

    -- checking if given new status is correct
    if ModifyReservationStatus10_0.status not in ('N', 'P', 'C') then
        raise_application_error(-20005, 'Wrong status!');
    end if;


    select r.trip_id
    into trip_id
    from Reservation r
    where r.RESERVATION_ID = ModifyReservationStatus10_0.reservation_id;

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
    where r.RESERVATION_ID = ModifyReservationStatus10_0.reservation_id;
    if ModifyReservationStatus10_0.status = old_status then
        raise_application_error(-20003, 'Given reservation already has such status!');
    end if;

    case
        when old_status = 'C'
            then if ModifyReservationStatus10_0.status <> 'N' then
                raise_application_error(-20003, 'Canceled reservation must be set to "N" (new) status first!');
                 end if;

                 if CheckAvailablePlaces(trip_id) = 0 then
                     raise_application_error(-20003, 'There are no free places left for the trip!');


                 end if;


        when old_status = 'P'
            then if (ModifyReservationStatus10_0.status <> 'C') then
                RAISE_APPLICATION_ERROR(-20006, 'P can only be changed to C status!');
            end if;

        else null;

        end case;


    update RESERVATION
    set STATUS = ModifyReservationStatus10_0.status
    where RESERVATION_ID = ModifyReservationStatus10_0.reservation_id;
end ;



create or replace trigger ForbiddenCapacityChange
    before update
    on trip
    for each row
begin
    if :old.MAX_NO_PLACES - :old.no_available_places > :new.max_no_places then
        raise_application_error(-20003, 'Dont');
    end if;
end;



create or replace procedure ModifyNoPlaces10_0(trip_id number, no_places number)
as
    reserved_places number;
    trip_exists     number;
    is_future       number;
begin

    -- checking if trip exists
    select count(*) into trip_exists from Trip t where t.TRIP_ID = ModifyNoPlaces10_0.trip_id;
    if trip_exists = 0 then
        raise_application_error(-20003, 'Such trip does not exist!');
    end if;

    -- checking if is future
    select count(*) into is_future from FUTURETRIPS9_0 ft where ft.TRIP_ID = ModifyNoPlaces10_0.trip_id;
    if is_future = 0 then
        raise_application_error(-20003, 'Cannot change number of places for trip which has already started (or ended)');
    end if;

    -- saving free places
    select (ft.max_no_places - ft.no_available_places)
    into reserved_places
    from TRIP ft
    where ft.trip_id = ModifyNoPlaces10_0.trip_id;

    update Trip
    set MAX_NO_PLACES       = ModifyNoPlaces10_0.no_places,
        NO_AVAILABLE_PLACES = ModifyNoPlaces10_0.no_places - reserved_places
    where trip_id = ModifyNoPlaces10_0.trip_id;


end;

