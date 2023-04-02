-- TripParticipants function

create or replace type TripParticipant as object
(
    country_name   varchar2(50),
    trip_date      date,
    trip_name      varchar2(50),
    firstname      varchar2(50),
    lastname       varchar2(50),
    reservation_id int,
    status         char(1)
);


create or replace type TripParticipantTable is table of TripParticipant;


create or replace function TripParticipants(trip_id int)
    return TripParticipantTable
    is
    result TripParticipantTable;
    valid  int;
begin
    select count(*) into valid from trip t where t.trip_id = TripParticipants.trip_id;
    if valid = 0 then
        raise_application_error(-20001, 'trip not found');
    end if;

    select TripParticipant(country_name,
                           trip_date,
                           trip_name,
                           firstname,
                           lastname,
                           reservation_id,
                           status) bulk collect
    into result
    from reservations1 r
    where r.trip_id = TripParticipants.trip_id;

    return result;
end;

-- ====================================================================================================================

-- PersonReservations function
create or replace function PersonReservations(person_id int)
    return TripParticipantTable
    is
    result TripParticipantTable;
    valid  int;
begin
    select count(*) into valid from person p where p.person_id = PersonReservations.person_id;
    if valid = 0 then
        raise_application_error(-20001, 'person not found');
    end if;

    select TripParticipant(country_name,
                           trip_date,
                           trip_name,
                           firstname,
                           lastname,
                           reservation_id,
                           status) bulk collect
    into result
    from reservations1 r
    where r.person_id = PersonReservations.person_id;

    return result;
end;

-- ====================================================================================================================

-- AvailableTrips function
create or replace type AvailableTrip is object
(
    country_name        varchar2(50),
    trip_date           date,
    trip_name           varchar2(50),
    max_no_places       int,
    no_available_places int
);

create or replace type AvailableTripTable is table of AvailableTrip;



create or replace function AvailableTrips(country varchar2, date_from date, date_to date)
    return AvailableTripTable
    is
    result AvailableTripTable;
    valid  int;
begin
    select count(*) into valid from country c where c.country_name = AvailableTrips.country;
    if valid = 0 then
        raise_application_error(-20001, 'country not found');
    end if;

    select AvailableTrip(country_name,
                         trip_date,
                         trip_name,
                         max_no_places,
                         no_available_places) bulk collect
    into result
    from AVAILABLETRIPSVIEW
    where COUNTRY_NAME = AvailableTrips.country
      and trip_date between AvailableTrips.date_from and AvailableTrips.date_to;


    return result;

end;

-- ====================================================================================================================

-- CheckAvailablePlaces function
create or replace function CheckAvailablePlaces(trip_id int)
    return boolean
    is
    result           boolean := false;
    available_places int;
begin
    select atv.NO_AVAILABLE_PLACES
    into available_places
    from AVAILABLETRIPSVIEW1 atv
    where atv.trip_id = CheckAvailablePlaces.trip_id;

    if available_places <> 0 then
        result := true;
    end if;

    return result;

end;

-- ====================================================================================================================
-- ====================================================================================================================
-- ====================================================================================================================
-- ====================================================================================================================


-- AddReservation procedure
create or replace procedure AddReservation(trip_id trip.trip_id%TYPE, person_id person.person_id%TYPE)
as
    person_exists  number;
    trip_available number;
begin

    select COUNT(*) into person_exists from person where person.person_id = AddReservation.person_id;

    if person_exists = 0 then
        RAISE_APPLICATION_ERROR(-20002, 'Person with chosen ID not found.');
    end if;

    select COUNT(*)
    into trip_available
    from AvailableTripsView1 atw
    where atw.trip_id = AddReservation.trip_id;

    if trip_available = 0 then
        RAISE_APPLICATION_ERROR(-20003, 'Trip with chosen ID is not available.');
    end if;


    insert into reservation (TRIP_ID, PERSON_ID, STATUS)
    values (AddReservation.trip_id, AddReservation.person_id, 'N');
end;

-- ====================================================================================================================

-- ModifyReservationStatus procedure
create or replace procedure ModifyReservationStatus(reservation_id number, status reservation.status%type)
as
    trip_id            int;
    old_status         reservation.status%type;
    reservation_exists number;
    is_future          number;
begin
    select COUNT(*)
    into reservation_exists
    from Reservations r
    where r.reservation_id = ModifyReservationStatus.reservation_id;

    if reservation_exists = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'Reservation with chosen ID does not exist!');
    end if;

    if ModifyReservationStatus.status not in ('N', 'P', 'C') then
        raise_application_error(-20005, 'Wrong status!');
    end if;

    -- for convenience
    select r.trip_id into trip_id from Reservations1 r where r.RESERVATION_ID = MODIFYRESERVATIONSTATUS.reservation_id;


    select COUNT(*)
    into is_future
    from FUTURETRIPS ft
    where ft.trip_id = TRIP_ID;

    if is_future = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'The trip for which given reservation was made has already started!');
    end if;


    -- here we know that input data are correct! now we just have to check if we can change states

    select r.status into old_status from reservation r where r.RESERVATION_ID = ModifyReservationStatus.reservation_id;
    -- status 'N' (new) can be changed to any status
    -- status 'P' (confirmed) can be changed to 'C'
    -- status 'C' cannot be changed to any status ?? can be set to new (?)
    case
        when old_status = 'C'
            then if MODIFYRESERVATIONSTATUS.status <> 'N' then
                raise_application_error(-20003, 'Canceled reservation must be set to "N" (new) status first!');
                 end if;

                 if CHECKAVAILABLEPLACES(trip_id) = false then
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


end;

-- ====================================================================================================================

-- ModifyNoPlaces procedure
create or replace procedure ModifyNoPlaces(trip_id number, no_places number)
as
    reserved_places number;
    trip_exists     number;
    is_future       number;
begin
    select count(*) into trip_exists from Trip t where t.TRIP_ID = MODIFYNOPLACES.trip_id;
    if trip_exists = 0 then
        raise_application_error(-20003, 'Such trip does not exist!');
    end if;

    select count(*) into is_future from FUTURETRIPS ft where ft.TRIP_ID = MODIFYNOPLACES.trip_id;
    if is_future = 0 then
        raise_application_error(-20003, 'Cannot change number of places for trip which has already started (or ended)');
    end if;

    select (ft.max_no_places - ft.no_available_places)
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
