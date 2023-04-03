-- dodawanie wycieczki trigger

create or replace trigger AddReservationLogTrigger
    after insert
    on reservation
    for each row
begin
    insert into log(reservation_id, log_date, status) VALUES (:new.reservation_id, current_date, :new.status);
end;

-- zmiana statusu trigger
create or replace trigger ChangeStatusTrigger
    after update
    on Reservation
    for each row
begin
    insert into log(reservation_id, log_date, status)
    values (:new.reservation_id, current_date, :new.status);
end;

-- usuwanie (wg mnie Loga, bo zmiana strategii loga w tytule jest)
create or replace trigger ForbiddenLogDeletionTrigger
    before delete
    on log
    for each row
begin
    raise_application_error(-20003, 'Cannot remove reservation from Log');

end;



-- nowe procki


create or replace procedure AddReservation1(trip_id trip.trip_id%TYPE, person_id person.person_id%TYPE)
as
    person_exists  number;
    trip_available number;
    reservation_id int;
begin

    select COUNT(*) into person_exists from person where person.person_id = AddReservation1.person_id;

    if person_exists = 0 then
        RAISE_APPLICATION_ERROR(-20002, 'Person with chosen ID not found.');
    end if;

    select COUNT(*)
    into trip_available
    from AvailableTripsView1 atw
    where atw.trip_id = AddReservation1.trip_id;

    if trip_available = 0 then
        RAISE_APPLICATION_ERROR(-20003, 'Trip with chosen ID is not available.');
    end if;


    insert into reservation (TRIP_ID, PERSON_ID, STATUS)
    values (AddReservation1.trip_id, AddReservation1.person_id, 'N')
    returning reservation_id into AddReservation1.reservation_id;
end;

-- ====================================================================================================================

-- ModifyReservationStatus procedure
create or replace procedure ModifyReservationStatus1(reservation_id number, status reservation.status%type)
as
    trip_id            int;
    old_status         reservation.status%type;
    reservation_exists number;
    is_future          number;
begin
    select COUNT(*)
    into reservation_exists
    from Reservations r
    where r.reservation_id = ModifyReservationStatus1.reservation_id;

    if reservation_exists = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'Reservation with chosen ID does not exist!');
    end if;

    if ModifyReservationStatus1.status not in ('N', 'P', 'C') then
        raise_application_error(-20005, 'Wrong status!');
    end if;

    -- for convenience
    select r.trip_id into trip_id from Reservations1 r where r.RESERVATION_ID = ModifyReservationStatus1.reservation_id;


    select COUNT(*)
    into is_future
    from FUTURETRIPS ft
    where ft.trip_id = TRIP_ID;

    if is_future = 0 then
        RAISE_APPLICATION_ERROR(-20005, 'The trip for which given reservation was made has already started!');
    end if;

    -- here we know that input data are correct! now we just have to check if we can change states

    select r.status into old_status from reservation r where r.RESERVATION_ID = ModifyReservationStatus1.reservation_id;
    if ModifyReservationStatus1.status = old_status then
        raise_application_error(-20003, 'Given reservation already has such status!');
    end if;

    case
        when old_status = 'C'
            then if ModifyReservationStatus1.status <> 'N' then
                raise_application_error(-20003, 'Canceled reservation must be set to "N" (new) status first!');
                 end if;

                 if CheckAvailablePlaces(trip_id) = 0 then
                     raise_application_error(-20003, 'There are no free places left for the trip!');


                 end if;


        when old_status = 'P'
            then if (ModifyReservationStatus1.status <> 'C') then
                RAISE_APPLICATION_ERROR(-20006, 'P can only be changed to C status!');
            end if;

        else null;

        end case;


    update RESERVATION
    set STATUS = ModifyReservationStatus1.status
    where RESERVATION_ID = ModifyReservationStatus1.reservation_id;


end ;



create or replace trigger CheckIfPlacesAvailableTrigger
    before insert on reservation
    for each row
    declare
        trip_id int;
    begin
        trip_id := :new.trip_id;
        if CHECKAVAILABLEPLACES(trip_id) = 0 then
            raise_application_error(-20003, 'There are no free places for that trip!');
        end if;

    end;




-- ex.8.
-- zakładamy, że autorowi chodziło o kontrolę czy dana rezerwacja może zostać dodana / zmieniony status

