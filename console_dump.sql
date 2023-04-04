select *
from TRIPS;
select *
from reservations;



select *
from reservation
         inner join trip t on t.trip_id = RESERVATION.TRIP_id
where TRIP_NAME = 'U nas na Podlasiu';


select *
from AVAILABLETRIPSVIEW;



select *
from TripParticipants(3);

select *
from TRIPPARTICIPANTs(6);


select *
from PERSONRESERVATIONS(1);



select * from AVAILABLETRIPSVIEW where COUNTRY_NAME = 'Polska';

select *
from AVAILABLETRIPS('Polska',
                    to_date('2023-04-07', 'YYYY-MM-DD'),
                    to_date('2026-01-01', 'YYYY-MM-DD'));


select * from AVAILABLETRIPSVIEW1;
select * from PERSON;

call ADDRESERVATION(10, 10);
select * from TRIPPARTICIPANTS(10);

select * from AVAILABLETRIPSVIEW1;
select * from RESERVATIONS1 r inner join AVAILABLETRIPSVIEW1 atv on r.TRIP_ID = atv.TRIP_ID;
select * from FUTURETRIPS ft inner join reservations1 r on r.TRIP_ID = ft.TRIP_ID;


call MODIFYRESERVATIONSTATUS(13, 'C');
call MODIFYNOPLACES(7, 6);

select * from AVAILABLETRIPSVIEW1;




call MODIFYRESERVATIONSTATUS(13, 'C');
select * from AVAILABLETRIPSVIEW1;

call ADDRESERVATION(9, 7);

select * from Reservation ;


select * from log;


select * from RESERVATION;
select * from log;
select * from AVAILABLETRIPSVIEW1;
select * from FUTURETRIPS;

select * from RESERVATIONS1 where trip_id = 9;

call ADDRESERVATION1(3, 7);



select * from reservations1 where TRIP_ID = 3;

call ADDRESERVATION1(9, 8);

select * from FUTURETRIPS;

call ADDRESERVATION2(9, 1);


declare
    av number;
begin
   select count(*)
    into av
   from AVAILABLETRIPSVIEW1 atv
    where atv.trip_id = 1 and NO_AVAILABLE_PLACES >0;
    DBMS_OUTPUT.PUT_LINE(av);

   end;







