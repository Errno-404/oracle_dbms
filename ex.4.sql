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
    result      TripParticipantTable;
    trip_exists int;
begin
    select count(*) into trip_exists from trip t where t.trip_id = TripParticipants.trip_id;
    if trip_exists = 0 then
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
    from reservations_1 r
    where r.trip_id = TripParticipants.trip_id;

    return result;
end;


-- PersonReservations function
create or replace function PersonReservations(person_id int)
    return TripParticipantTable
    is
    result        TripParticipantTable;
    person_exists int;
begin
    select count(*) into person_exists from person p where p.person_id = PersonReservations.person_id;
    if person_exists = 0 then
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
    from reservations_1 r
    where r.person_id = PersonReservations.person_id;

    return result;
end;


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
    result         AvailableTripTable;
    country_exists int;
begin
    select count(*) into country_exists from country c where c.country_name = AvailableTrips.country;
    if country_exists = 0 then
        raise_application_error(-20001, 'country not found');
    end if;


    if date_from > date_to then
        raise_application_error(-20003,
                                'Date given as the second argument should be earlier ' ||
                                'than the one provided as the 3rd argument!');
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
