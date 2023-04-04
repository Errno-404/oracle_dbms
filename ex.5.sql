-- CheckAvailablePlaces function
create or replace function CheckAvailablePlaces(trip_id int)
    return int
    is
    result           int := 0;
    available_places int;
begin
    select count(*)
    into available_places
    from AvailableTripsView_1 atv
    where atv.trip_id = CheckAvailablePlaces.trip_id;


    if available_places <> 0 then
        result := 1;
    end if;

    return result;

end;

-- AddReservation procedure
create or replace procedure AddReservation(trip_id trip.trip_id%TYPE, person_id person.person_id%TYPE)
as
    person_exists  number;
    trip_exists    int;
    is_future      int;
    is_available   int;
begin

    -- checking if person exists
    select COUNT(*) into person_exists from person where person.person_id = AddReservation.person_id;
    if person_exists = 0 then
        RAISE_APPLICATION_ERROR(-20002, 'Person with chosen ID not found.');
    end if;

    -- checking if trip exists
    select count(*) into trip_exists from trip where trip.trip_id = Addreservation.trip_id;
    if trip_exists = 0 then
        raise_application_error(-20003, 'Such trip does not exist!');
    end if;

    -- checking if trip is in the future
    select count(*) into is_future from FUTURETRIPS where FUTURETRIPS.TRIP_ID = AddReservation.trip_id;
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
    values (AddReservation.trip_id, AddReservation.person_id, 'N');

end;


-- ModifyReservationStatus procedure
create or replace procedure ModifyReservationStatus(reservation_id number, status reservation.status%type)
as
    trip_id            int;
    old_status         reservation.status%type;
    reservation_exists number;
    is_future          number;
begin

    -- checking if reservation exists
    select COUNT(*)
    into reservation_exists
    from Reservation r
    where r.reservation_id = ModifyReservationStatus.reservation_id;
    if reservation_exists = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'Reservation with chosen ID does not exist!');
    end if;

    -- checking if given new status is correct
    if ModifyReservationStatus.status not in ('N', 'P', 'C') then
        raise_application_error(-20005, 'Wrong status!');
    end if;


    select r.trip_id into trip_id from Reservation r where r.RESERVATION_ID = MODIFYRESERVATIONSTATUS.reservation_id;

    -- checking if trip has already started
    select COUNT(*)
    into is_future
    from FUTURETRIPS ft
    where ft.trip_id = TRIP_ID;

    if is_future = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'The trip for which given reservation was made has already started!');
    end if;

    -- here we know that input data are correct! now we just have to check if we can change states

    select r.status into old_status from reservation r where r.RESERVATION_ID = ModifyReservationStatus.reservation_id;
    if ModifyReservationStatus.status = old_status then
        raise_application_error(-20003, 'Given reservation already has such status!');
    end if;

    case
        when old_status = 'C'
            then if MODIFYRESERVATIONSTATUS.status <> 'N' then
                raise_application_error(-20003, 'Canceled reservation must be set to "N" (new) status first!');
                 end if;

                 if CheckAvailablePlaces(trip_id) = 0 then
                     raise_application_error(-20003, 'There are no free places left for the trip!');


                 end if;


        when old_status = 'P'
            then if (ModifyReservationStatus.status <> 'C') then
                RAISE_APPLICATION_ERROR(-20006, 'P can only be changed to C status!');
            end if;

        else null;

        end case;


    update RESERVATION
    set STATUS = ModifyReservationStatus.status
    where RESERVATION_ID = ModifyReservationStatus.reservation_id;


end ;


-- ModifyNoPlaces procedure
create or replace procedure ModifyNoPlaces(trip_id number, no_places number)
as
    reserved_places number;
    trip_exists     number;
    is_future       number;
begin

    -- checking if trip exists
    select count(*) into trip_exists from Trip t where t.TRIP_ID = MODIFYNOPLACES.trip_id;
    if trip_exists = 0 then
        raise_application_error(-20003, 'Such trip does not exist!');
    end if;

    -- checking if is future
    select count(*) into is_future from FUTURETRIPS ft where ft.TRIP_ID = MODIFYNOPLACES.trip_id;
    if is_future = 0 then
        raise_application_error(-20003, 'Cannot change number of places for trip which has already started (or ended)');
    end if;

    -- saving free places
    select (ft.max_no_places - ft.no_available_places_v)
    into reserved_places
    from FUTURETRIPS ft
    where ft.trip_id = ModifyNoPlaces.trip_id;


    if no_places < 0 or reserved_places > no_places
    then
        raise_application_error(-20007, 'Given value was less than 0 or less than currently reserved places!');
    end if;

    update Trip
    set MAX_NO_PLACES = ModifyNoPlaces.no_places
    where trip_id = ModifyNoPlaces.trip_id;

end;