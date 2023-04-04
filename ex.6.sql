create table log
(
	log_id int  generated always as identity not null,
	reservation_id int not null,
	log_date date  not null,
	status char(1),
	constraint log_pk primary key ( log_id ) enable
);

alter table log
add constraint log_chk1 check
(status in ('N','P','C')) enable;

alter table log
add constraint log_fk1 foreign key
( reservation_id ) references reservation ( reservation_id ) enable;



-- AddReservation procedure
create or replace procedure AddReservation6_0(trip_id trip.trip_id%TYPE, person_id person.person_id%TYPE)
as
    person_exists  number;
    trip_exists    int;
    is_future      int;
    is_available   int;
    reservation_id int;
begin

    -- checking if person exists
    select COUNT(*) into person_exists from person where person.person_id = AddReservation6_0.person_id;
    if person_exists = 0 then
        RAISE_APPLICATION_ERROR(-20002, 'Person with chosen ID not found.');
    end if;

    -- checking if trip exists
    select count(*) into trip_exists from trip where trip.trip_id = AddReservation6_0.trip_id;
    if trip_exists = 0 then
        raise_application_error(-20003, 'Such trip does not exist!');
    end if;

    -- checking if trip is in the future
    select count(*) into is_future from FUTURETRIPS where FUTURETRIPS.TRIP_ID = AddReservation6_0.trip_id;
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
    values (AddReservation6_0.trip_id, AddReservation6_0.person_id, 'N')
    returning reservation_id into AddReservation6_0.reservation_id;

    insert into log(reservation_id, log_date, status)
    values (AddReservation6_0.reservation_id, current_date, 'N');
end;


-- ModifyReservationStatus procedure
create or replace procedure ModifyReservationStatus6_0(reservation_id number, status reservation.status%type)
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
    where r.reservation_id = ModifyReservationStatus6_0.reservation_id;
    if reservation_exists = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'Reservation with chosen ID does not exist!');
    end if;

    -- checking if given new status is correct
    if ModifyReservationStatus6_0.status not in ('N', 'P', 'C') then
        raise_application_error(-20005, 'Wrong status!');
    end if;


    select r.trip_id into trip_id from Reservations_1 r where r.RESERVATION_ID = ModifyReservationStatus6_0.reservation_id;

    -- checking if trip has already started
    select COUNT(*)
    into is_future
    from FUTURETRIPS ft
    where ft.trip_id = TRIP_ID;

    if is_future = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'The trip for which given reservation was made has already started!');
    end if;

    -- here we know that input data are correct! now we just have to check if we can change states

    select r.status into old_status from reservation r where r.RESERVATION_ID = ModifyReservationStatus6_0.reservation_id;
    if ModifyReservationStatus6_0.status = old_status then
        raise_application_error(-20003, 'Given reservation already has such status!');
    end if;

    case
        when old_status = 'C'
            then if ModifyReservationStatus6_0.status <> 'N' then
                raise_application_error(-20003, 'Canceled reservation must be set to "N" (new) status first!');
                 end if;

                 if CheckAvailablePlaces(trip_id) = 0 then
                     raise_application_error(-20003, 'There are no free places left for the trip!');


                 end if;


        when old_status = 'P'
            then if (ModifyReservationStatus6_0.status <> 'C') then
                RAISE_APPLICATION_ERROR(-20006, 'P can only be changed to C status!');
            end if;

        else null;

        end case;


    update RESERVATION
    set STATUS = ModifyReservationStatus6_0.status
    where RESERVATION_ID = ModifyReservationStatus6_0.reservation_id;


    insert into Log(reservation_id, log_date, status)
    values (ModifyReservationStatus6_0.reservation_id, current_date, ModifyReservationStatus6_0.status);


end ;
