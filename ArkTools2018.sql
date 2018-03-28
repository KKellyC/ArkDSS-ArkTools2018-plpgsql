--
-- PostgreSQL database dump
--

-- Dumped from database version 9.3.20
-- Dumped by pg_dump version 9.5.5

-- Started on 2018-03-27 20:43:12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 8 (class 2615 OID 16398)
-- Name: alert; Type: SCHEMA; Schema: -; Owner: ark_admin
--

CREATE SCHEMA alert;


ALTER SCHEMA alert OWNER TO ark_admin;

--
-- TOC entry 11 (class 2615 OID 25107)
-- Name: archive; Type: SCHEMA; Schema: -; Owner: ark_admin
--

CREATE SCHEMA archive;


ALTER SCHEMA archive OWNER TO ark_admin;

--
-- TOC entry 9 (class 2615 OID 16397)
-- Name: data; Type: SCHEMA; Schema: -; Owner: ark_admin
--

CREATE SCHEMA data;


ALTER SCHEMA data OWNER TO ark_admin;

--
-- TOC entry 12 (class 2615 OID 25227)
-- Name: tools; Type: SCHEMA; Schema: -; Owner: ark_admin
--

CREATE SCHEMA tools;


ALTER SCHEMA tools OWNER TO ark_admin;

--
-- TOC entry 10 (class 2615 OID 16399)
-- Name: web; Type: SCHEMA; Schema: -; Owner: ark_admin
--

CREATE SCHEMA web;


ALTER SCHEMA web OWNER TO ark_admin;

--
-- TOC entry 1 (class 3079 OID 11756)
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- TOC entry 2577 (class 0 OID 0)
-- Dependencies: 1
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


SET search_path = tools, pg_catalog;

--
-- TOC entry 305 (class 1255 OID 25600)
-- Name: fetchit_postsubmit_assoc_loc_to_water_colors_edit(); Type: FUNCTION; Schema: tools; Owner: ark_admin
--

CREATE FUNCTION fetchit_postsubmit_assoc_loc_to_water_colors_edit() RETURNS integer
    LANGUAGE plpgsql
    AS $$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is called by the fetchit egrid "Associate Selected Location to Water Type(s)" 
	allowing a user to edit the location to water type (color) associations

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

---------
--STEPS--
---------

/*1. Clear records in the assoc data table (data.assoc_loc_to_water_colors) 
     that already exist for the selected location (loc_ndx)*/
DELETE FROM data.assoc_loc_to_water_colors d
USING (SELECT DISTINCT loc_ndx FROM tools.egrid_assoc_locations_and_water_colors) e
 WHERE d.loc_ndx = e.loc_ndx;

/*2. Insert records into the assoc data table (data.assoc_loc_to_water_colors) 
     from the fetchit egrid table for the selected location (loc_ndx)
     where assoc_true IS TRUE */
INSERT INTO data.assoc_loc_to_water_colors(loc_ndx, wc_ndx)
SELECT loc_ndx, wc_ndx
  FROM tools.egrid_assoc_locations_and_water_colors
WHERE assoc_true IS TRUE;

/*3. Prep (clear) egrid landing table (UNNECESSARY?) */
DELETE FROM tools.egrid_assoc_locations_and_water_colors;

/*4. Refresh egrid landing table based on location selected (UNNECESSARY?)*/
INSERT INTO tools.egrid_assoc_locations_and_water_colors(
            loc_ndx, wc_ndx, wc_name, assoc_true)
SELECT loc_ndx, wc_ndx, wc_name, assoc_true
  FROM tools.egrid_build_assoc_locations_and_water_colors;    

RETURN 42;

END
$$;


ALTER FUNCTION tools.fetchit_postsubmit_assoc_loc_to_water_colors_edit() OWNER TO ark_admin;

--
-- TOC entry 308 (class 1255 OID 25706)
-- Name: fetchit_postsubmit_assoc_user_to_loc_triple_edit(); Type: FUNCTION; Schema: tools; Owner: ark_admin
--

CREATE FUNCTION fetchit_postsubmit_assoc_user_to_loc_triple_edit() RETURNS integer
    LANGUAGE plpgsql
    AS $$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is called by the fetchit param form "Select Location(s) to Associate to Selected User"
	allowing a user to select location(s) to associate to the selected user (and then move on to the 
	user-to-water-color assoc to complete the triple 

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

---------
--STEPS--
---------

/*1. Clear records in the assoc data table (data.assoc_user_to_loc) 
     that already exist for the selected user (user_ndx)*/
DELETE FROM data.assoc_user_to_loc d
USING (SELECT DISTINCT user_ndx FROM tools.fetchit_landing_user_to_manage_last_submit) t
 WHERE d.user_ndx = t.user_ndx;

/*2. Insert records into the assoc data table (data.assoc_user_to_loc) 
     from the fetchit landing table and with the cross joined user_ndx*/
INSERT INTO data.assoc_user_to_loc(user_ndx, loc_ndx)
SELECT user_ndx, loc_ndx
 FROM tools.fetchit_landing_selected_loc_for_user_wc_triple_assoc
CROSS JOIN (SELECT DISTINCT user_ndx FROM tools.fetchit_landing_user_to_manage_last_submit) t;

/*3. Prep (clear) param form landing table (UNNECESSARY?) */
DELETE FROM tools.fetchit_landing_selected_loc_for_user_wc_triple_assoc;

/*4. Refresh egrid landing table based on user selected (UNNECESSARY?)*/
INSERT INTO tools.fetchit_landing_selected_loc_for_user_wc_triple_assoc(loc_ndx)
SELECT loc_ndx
  FROM data.assoc_user_to_loc d
  CROSS JOIN (SELECT DISTINCT user_ndx FROM tools.fetchit_landing_user_to_manage_last_submit) t
WHERE d.user_ndx = t.user_ndx;

/*5. Prep (clear) egrid landing table for next step: associating user to water types/colors */
DELETE FROM tools.fetchit_landing_selected_wc_for_user_loc_triple_assoc;

/*6. Refresh table display landing table for next step based on location(s) selected */
INSERT INTO tools.fetchit_landing_selected_wc_for_user_loc_triple_assoc(wc_ndx)
SELECT wc_ndx
  FROM tools.table_display_build_assoc_triple_users_locs_wcs_prep
WHERE assoc_true IS TRUE;

RETURN 42;

END
$$;


ALTER FUNCTION tools.fetchit_postsubmit_assoc_user_to_loc_triple_edit() OWNER TO ark_admin;

--
-- TOC entry 309 (class 1255 OID 25705)
-- Name: fetchit_postsubmit_assoc_user_to_wc_triple_edit(); Type: FUNCTION; Schema: tools; Owner: ark_admin
--

CREATE FUNCTION fetchit_postsubmit_assoc_user_to_wc_triple_edit() RETURNS integer
    LANGUAGE plpgsql
    AS $$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is called by the fetchit table display "Associate Selected User and Location(s) to Water Type(s)" 
	allowing a user to edit the user water type (color) associations (with the locations triple in mind)

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

---------
--STEPS--
---------

/*1. Clear records in the assoc data table (data.assoc_user_to_water_color) 
     that already exist for the selected user (user_ndx)*/
DELETE FROM data.assoc_user_to_water_color d
USING (SELECT DISTINCT user_ndx FROM tools.table_display_build_assoc_triple_users_locs_wcs_prep) t
 WHERE d.user_ndx = t.user_ndx;

/*2. Insert records into the assoc data table (data.assoc_user_to_water_color) 
     from the fetchit landing table */
INSERT INTO data.assoc_user_to_water_color(user_ndx, wc_ndx)
SELECT t.user_ndx, f.wc_ndx
  FROM tools.fetchit_landing_selected_wc_for_user_loc_triple_assoc f
CROSS JOIN (SELECT DISTINCT user_ndx FROM tools.table_display_build_assoc_triple_users_locs_wcs_prep) t;

/*3. Prep (clear) egrid landing table */
DELETE FROM tools.fetchit_landing_selected_wc_for_user_loc_triple_assoc;

/*4. Refresh table display landing table based on location selected */
INSERT INTO tools.fetchit_landing_selected_wc_for_user_loc_triple_assoc(wc_ndx)
SELECT wc_ndx
  FROM tools.table_display_build_assoc_triple_users_locs_wcs_prep
WHERE assoc_true IS TRUE;

RETURN 42;

END
$$;


ALTER FUNCTION tools.fetchit_postsubmit_assoc_user_to_wc_triple_edit() OWNER TO ark_admin;

--
-- TOC entry 303 (class 1255 OID 25574)
-- Name: fetchit_postsubmit_list_locations_add_new(); Type: FUNCTION; Schema: tools; Owner: ark_admin
--

CREATE FUNCTION fetchit_postsubmit_list_locations_add_new() RETURNS integer
    LANGUAGE plpgsql
    AS $$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is called by the fetchit egrid "Add an Location" allowing a user to add a new location
	to data.list_locations 

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

---------
--STEPS--
---------

/*1. Add record from landing table (tools.egrid_list_locations_add_new)
     to the data table (data.list_locations)*/
INSERT INTO data.list_locations(
            loc_name, loc_wdid, dd_release, 
            dd_exch_to, dd_exch_from, dd_capture_from, display_order)   
SELECT loc_name, loc_wdid, dd_release, 
       dd_exch_to, dd_exch_from, dd_capture_from, display_order
FROM tools.egrid_list_locations_add_new;


/*2. Prep (clear) egrid landing tables */
DELETE FROM tools.egrid_list_locations_add_new;
DELETE FROM tools.egrid_list_locations_edit_delete;

/*3. Refresh egrid landing table for edit/delete */
INSERT INTO tools.egrid_list_locations_edit_delete(
            loc_ndx, loc_name, loc_wdid, dd_release, 
            dd_exch_to, dd_exch_from, dd_capture_from, display_order)
SELECT loc_ndx, loc_name, loc_wdid, dd_release, 
       dd_exch_to, dd_exch_from, dd_capture_from, display_order
FROM data.list_locations
ORDER BY CASE WHEN dd_release OR dd_exch_to OR dd_exch_from OR dd_capture_from IS TRUE THEN TRUE
		ELSE FALSE END DESC, loc_name;    

RETURN 42;

END
$$;


ALTER FUNCTION tools.fetchit_postsubmit_list_locations_add_new() OWNER TO ark_admin;

--
-- TOC entry 302 (class 1255 OID 25576)
-- Name: fetchit_postsubmit_list_locations_edit_delete(); Type: FUNCTION; Schema: tools; Owner: ark_admin
--

CREATE FUNCTION fetchit_postsubmit_list_locations_edit_delete() RETURNS integer
    LANGUAGE plpgsql
    AS $$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is called by the fetchit egrid "Edit or Remove an Entity" allowing a user to 
	remove an entity from data.list_locations 

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

---------
--STEPS--
---------

/*1. Update records in the data table (data.list_locations)
     by joining on the PK loc_ndx*/
UPDATE data.list_locations
   SET loc_name=e.loc_name, loc_wdid=e.loc_wdid, dd_release=e.dd_release, 
       dd_exch_to=e.dd_exch_to, dd_exch_from=e.dd_exch_from, 
       dd_capture_from=e.dd_capture_from, display_order=e.display_order
FROM tools.egrid_list_locations_edit_delete e
 WHERE list_locations.loc_ndx = e.loc_ndx;

/*2. Delete records from the data table (data.list_locations)
     where delete_bool is TRUE and by joining on the PK loc_ndx*/
DELETE FROM data.list_locations d
 USING tools.egrid_list_locations_edit_delete e
 WHERE e.delete_bool IS TRUE AND d.loc_ndx = e.loc_ndx;

/*3. Prep (clear) egrid landing table */
DELETE FROM tools.egrid_list_locations_edit_delete;

/*4. Refresh egrid landing table for edit/delete */
INSERT INTO tools.egrid_list_locations_edit_delete(
            loc_ndx, loc_name, loc_wdid, dd_release, 
            dd_exch_to, dd_exch_from, dd_capture_from, display_order)
SELECT loc_ndx, loc_name, loc_wdid, dd_release, 
       dd_exch_to, dd_exch_from, dd_capture_from, display_order
FROM data.list_locations
ORDER BY dd_release DESC, dd_capture_from DESC, dd_exch_to DESC, dd_exch_from DESC, display_order, loc_name;    

RETURN 42;

END
$$;


ALTER FUNCTION tools.fetchit_postsubmit_list_locations_edit_delete() OWNER TO ark_admin;

--
-- TOC entry 300 (class 1255 OID 25543)
-- Name: fetchit_postsubmit_list_ownerentities_add_new(); Type: FUNCTION; Schema: tools; Owner: ark_admin
--

CREATE FUNCTION fetchit_postsubmit_list_ownerentities_add_new() RETURNS integer
    LANGUAGE plpgsql
    AS $$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is called by the fetchit egrid "Add an Entity" allowing a user to add a new entity
	to data.list_ownerentities 

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

---------
--STEPS--
---------

/*1. Add record from landing table (tools.egrid_list_ownerentities_add_new)
     to the data table (data.list_ownerentities)*/
INSERT INTO data.list_ownerentities(
            own_name, dd_transfer_from, 
            dd_transfer_to, own_email, own_phone)     
SELECT own_name, dd_transfer_from, 
       dd_transfer_to, own_email, own_phone
FROM tools.egrid_list_ownerentities_add_new;


/*2. Prep (clear) egrid landing tables */
DELETE FROM tools.egrid_list_ownerentities_add_new;
DELETE FROM tools.egrid_list_ownerentities_edit_delete;

/*3. Refresh egrid landing table for edit/delete */
INSERT INTO tools.egrid_list_ownerentities_edit_delete(
            own_ndx, own_name, dd_transfer_from, 
            dd_transfer_to, own_email, own_phone)
SELECT own_ndx, own_name, dd_transfer_from, 
       dd_transfer_to, own_email, own_phone
FROM data.list_ownerentities
ORDER BY CASE WHEN dd_transfer_from OR dd_transfer_to IS TRUE THEN TRUE
		ELSE FALSE END DESC, own_name;    

RETURN 42;

END
$$;


ALTER FUNCTION tools.fetchit_postsubmit_list_ownerentities_add_new() OWNER TO ark_admin;

--
-- TOC entry 297 (class 1255 OID 25542)
-- Name: fetchit_postsubmit_list_ownerentities_edit_delete(); Type: FUNCTION; Schema: tools; Owner: ark_admin
--

CREATE FUNCTION fetchit_postsubmit_list_ownerentities_edit_delete() RETURNS integer
    LANGUAGE plpgsql
    AS $$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is called by the fetchit egrid "Edit or Remove an Entity" allowing a user to 
	remove an entity from data.list_ownerentities 

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

---------
--STEPS--
---------

/*1. Update records in the data table (data.list_ownerentities)
     by joining on the PK own_ndx*/
UPDATE data.list_ownerentities
   SET own_name=e.own_name, dd_transfer_from=e.dd_transfer_from, 
dd_transfer_to=e.dd_transfer_to, own_email=e.own_email, own_phone=e.own_phone
FROM tools.egrid_list_ownerentities_edit_delete e
 WHERE list_ownerentities.own_ndx = e.own_ndx;

/*2. Delete records from the data table (data.list_ownerentities)
     where delete_bool is TRUE and by joining on the PK own_ndx*/
DELETE FROM data.list_ownerentities d
 USING tools.egrid_list_ownerentities_edit_delete e
 WHERE e.delete_bool IS TRUE AND d.own_ndx = e.own_ndx;

/*3. Prep (clear) egrid landing table */
DELETE FROM tools.egrid_list_ownerentities_edit_delete;

/*4. Refresh egrid landing table */
INSERT INTO tools.egrid_list_ownerentities_edit_delete(
            own_ndx, own_name, dd_transfer_from, 
            dd_transfer_to, own_email, own_phone)
SELECT own_ndx, own_name, dd_transfer_from, 
       dd_transfer_to, own_email, own_phone
FROM data.list_ownerentities
ORDER BY CASE WHEN dd_transfer_from OR dd_transfer_to IS TRUE THEN TRUE
		ELSE FALSE END DESC, own_name;         

RETURN 42;

END
$$;


ALTER FUNCTION tools.fetchit_postsubmit_list_ownerentities_edit_delete() OWNER TO ark_admin;

--
-- TOC entry 298 (class 1255 OID 25575)
-- Name: fetchit_postsubmit_list_water_colors_add_new(); Type: FUNCTION; Schema: tools; Owner: ark_admin
--

CREATE FUNCTION fetchit_postsubmit_list_water_colors_add_new() RETURNS integer
    LANGUAGE plpgsql
    AS $$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is called by the fetchit egrid "Add a Water Type" allowing a user to add a new water color
	to data.list_water_colors 

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

---------
--STEPS--
---------

/*1. Add record from landing table (tools.egrid_list_water_colors_add_new)
     to the data table (data.list_water_colors)*/
INSERT INTO data.list_water_colors(
            wc_name, dd_release, dd_exch_to, dd_exch_from, 
            dd_transfer_from, dd_transfer_to, dd_capture_from, display_order)   
SELECT wc_name, dd_release, dd_exch_to, dd_exch_from, 
       dd_transfer_from, dd_transfer_to, dd_capture_from, display_order
FROM tools.egrid_list_water_colors_add_new;


/*2. Prep (clear) egrid landing tables */
DELETE FROM tools.egrid_list_water_colors_add_new;
DELETE FROM tools.egrid_list_water_colors_edit_delete;

/*3. Refresh egrid landing table for edit/delete */
INSERT INTO tools.egrid_list_water_colors_edit_delete(
            wc_ndx, wc_name, dd_release, dd_exch_to, dd_exch_from, 
            dd_transfer_from, dd_transfer_to, dd_capture_from, display_order)
SELECT wc_ndx, wc_name, dd_release, dd_exch_to, dd_exch_from, 
       dd_transfer_from, dd_transfer_to, dd_capture_from, display_order
FROM data.list_water_colors
ORDER BY CASE WHEN dd_release OR dd_exch_to OR dd_exch_from OR dd_transfer_from
		OR dd_transfer_to OR dd_capture_from IS TRUE THEN TRUE
		ELSE FALSE END DESC, wc_name;    

RETURN 42;

END
$$;


ALTER FUNCTION tools.fetchit_postsubmit_list_water_colors_add_new() OWNER TO ark_admin;

--
-- TOC entry 294 (class 1255 OID 25577)
-- Name: fetchit_postsubmit_list_water_colors_edit_delete(); Type: FUNCTION; Schema: tools; Owner: ark_admin
--

CREATE FUNCTION fetchit_postsubmit_list_water_colors_edit_delete() RETURNS integer
    LANGUAGE plpgsql
    AS $$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is called by the fetchit egrid "Edit or Remove an Water Type" allowing a user to 
	edit or remove records in data.list_water_colors 

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

---------
--STEPS--
---------

/*1. Update records in the data table (data.list_water_colors)
     by joining on the PK wc_ndx*/
UPDATE data.list_water_colors
   SET wc_name=e.wc_name, dd_release=e.dd_release, dd_exch_to=e.dd_exch_to, 
       dd_exch_from=e.dd_exch_from, dd_transfer_from=e.dd_transfer_from,
       dd_transfer_to=e.dd_transfer_to, dd_capture_from=e.dd_capture_from, display_order=e.display_order
FROM tools.egrid_list_water_colors_edit_delete e
 WHERE list_water_colors.wc_ndx = e.wc_ndx;

/*2. Delete records from the data table (data.list_water_colors)
     where delete_bool is TRUE and by joining on the PK wc_ndx*/
DELETE FROM data.list_water_colors d
 USING tools.egrid_list_water_colors_edit_delete e
 WHERE e.delete_bool IS TRUE AND d.wc_ndx = e.wc_ndx;

/*3. Prep (clear) egrid landing table */
DELETE FROM tools.egrid_list_water_colors_edit_delete;

/*4. Refresh egrid landing table */
INSERT INTO tools.egrid_list_water_colors_edit_delete(
            wc_ndx, wc_name, dd_release, dd_exch_to, dd_exch_from, 
            dd_transfer_from, dd_transfer_to, dd_capture_from, display_order)
SELECT wc_ndx, wc_name, dd_release, dd_exch_to, dd_exch_from, 
       dd_transfer_from, dd_transfer_to, dd_capture_from, display_order
FROM data.list_water_colors
ORDER BY 
dd_release DESC, --dd_exch_to, dd_exch_from, dd_transfer_from, dd_transfer_to, dd_capture_from, 
display_order, wc_name;    

RETURN 42;

END
$$;


ALTER FUNCTION tools.fetchit_postsubmit_list_water_colors_edit_delete() OWNER TO ark_admin;

--
-- TOC entry 304 (class 1255 OID 25599)
-- Name: fetchit_postsubmit_select_loc_for_wc_assoc(); Type: FUNCTION; Schema: tools; Owner: ark_admin
--

CREATE FUNCTION fetchit_postsubmit_select_loc_for_wc_assoc() RETURNS integer
    LANGUAGE plpgsql
    AS $$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is called by the fetchit param form "Select Location to Manage" allowing a user to 
	select a location to manage for associations to water types (colors)	

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

---------
--STEPS--
---------

/*1. Prep (clear) egrid landing table */
DELETE FROM tools.egrid_assoc_locations_and_water_colors;

/*2. Refresh egrid landing table based on location selected */
INSERT INTO tools.egrid_assoc_locations_and_water_colors(
            loc_ndx, wc_ndx, wc_name, assoc_true)
SELECT loc_ndx, wc_ndx, wc_name, assoc_true
  FROM tools.egrid_build_assoc_locations_and_water_colors;    

RETURN 42;

END
$$;


ALTER FUNCTION tools.fetchit_postsubmit_select_loc_for_wc_assoc() OWNER TO ark_admin;

--
-- TOC entry 307 (class 1255 OID 25414)
-- Name: fetchit_postsubmit_select_user_to_manage(); Type: FUNCTION; Schema: tools; Owner: ark_admin
--

CREATE FUNCTION fetchit_postsubmit_select_user_to_manage() RETURNS text
    LANGUAGE plpgsql
    AS $$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is called by the fetchit form allowing a user to select a user to be managed
	in the user to entities, user to locations and user to water colors data management tools
	pages.  The form includes a user selection, a select all check box, and a select none check 
        box, and affects all three sets of associations.

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

---------
--STEPS--
---------

/*1. Update associations based on select all or select none selections
     Note, the underlying "last_submit" view ensures these actions are only applied to the
     user included in the latest submission of the form */
     
-- Insert all associations if submission included select all flag
SELECT user_ndx,oe.own_ndx, l.selectall_flag 
FROM tools.fetchit_landing_user_to_manage_last_submit l
CROSS JOIN data.list_ownerentities oe 
WHERE l.selectall_flag;
--(insert associations above into user to entities, user to locations, and user to water colors)

-- Remove all associations if submission included select none flag
SELECT user_ndx,l.selectnone_flag 
FROM tools.fetchit_landing_user_to_manage_last_submit l
WHERE l.selectnone_flag;
--(remove all associations for the user returned above from user to locations, and user to water colors)

/*2. Prep (clear) egrid records
     Note, the underlying "last_submit" view ensures these actions are only applied to the
     user included in the latest submission of the form */

-- Clear egrid for last submitted user id
DELETE FROM tools.egrid_assoc_users_and_entities ue
USING tools.fetchit_landing_user_to_manage_last_submit ls
WHERE ls.drupal_userid=ue.drupal_userid;

--** repeat above for the other two egrids, users to locs and users to water colors **

/*2. Insert egrid records for the selected user */

-- Enter egrid records (view just pulls records for last submitted user id)
-- NOTE the underlying view being inserted sorts records in the egrid so that already selected associations
--      appear at the top, and then the rest of the potential associations are alphabetized below that.
INSERT INTO tools.egrid_assoc_users_and_entities
SELECT * FROM tools.egrid_build_assoc_users_and_entities;

--** repeat above for the other two egrids, users to locs and users to water colors **

/*3. Prep (clear) param form landing table for next step: selecting and associating location(s) to selected user */
DELETE FROM tools.fetchit_landing_selected_loc_for_user_wc_triple_assoc;

/*4. Refresh egrid landing table for next step based on user selected */
INSERT INTO tools.fetchit_landing_selected_loc_for_user_wc_triple_assoc(loc_ndx)
SELECT loc_ndx
  FROM data.assoc_user_to_loc d
  CROSS JOIN (SELECT DISTINCT user_ndx FROM tools.fetchit_landing_user_to_manage_last_submit) t
WHERE d.user_ndx = t.user_ndx;

END
$$;


ALTER FUNCTION tools.fetchit_postsubmit_select_user_to_manage() OWNER TO ark_admin;

SET search_path = web, pg_catalog;

--
-- TOC entry 301 (class 1255 OID 25516)
-- Name: create_landing_table_record(integer, integer); Type: FUNCTION; Schema: web; Owner: ark_admin
--

CREATE FUNCTION create_landing_table_record(userid integer, request_type integer) RETURNS text
    LANGUAGE plpgsql
    AS $_$


DECLARE
check_qry text;
table_name_qry text;
landing_table_check_qry text;
landing_table_check_result text;
landing_ndx_qry integer;
landing_ndx_result text;
landing_table_insert_qry text;

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is used to insert a record into the form 1
	landing tables as well as a user specified landing table
	on form page load.

	This function runs when a user hits the next button on form 1.

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

/* =================================================================================================	

STEPS
-------
1. Check if record for Drupal Userid already exists
	a. if record exists, do nothing and exit function
	b. else, insert record into form1 table and user specified
	landing table

================================================================================================= */

/* Check if a record is found for the current drupal user in form 1 table */
SELECT d.drupal_userid into check_qry 
FROM web.landing_form1 d 
WHERE d.drupal_userid = userid;


SELECT d.primary_landing_table_descrip INTO table_name_qry
FROM web.assoc_request_to_landing_tables_view d
WHERE d.req_type_ndx = request_type;


/* 
If a record is not found, insert Drupal userid into form 1 table and user specified landing table
Else, do nothing
*/
IF NOT FOUND then
  EXECUTE 'INSERT INTO web.landing_form1 (drupal_userid) VALUES($1)'
  USING userid;

  SELECT landing_ndx INTO landing_ndx_qry FROM web.landing_form1 WHERE drupal_userid = userid; 

  EXECUTE 'INSERT INTO ' || table_name_qry || ' (landing_ndx, drupal_userid) VALUES($1,$2)'
  USING landing_ndx_qry, userid;
  
  RETURN 'Records inserted into two landing tables';
ELSE
  landing_table_check_qry := format('
	SELECT d.drupal_userid
	FROM %s d 
	WHERE d.drupal_userid = $1',
	table_name_qry);
  EXECUTE landing_table_check_qry INTO landing_table_check_result USING userid;

  IF landing_table_check_result IS NULL then
	SELECT landing_ndx INTO landing_ndx_qry FROM web.landing_form1 WHERE drupal_userid = userid;
	EXECUTE 'INSERT INTO ' || table_name_qry || ' (landing_ndx, drupal_userid) VALUES($1,$2)'
	USING landing_ndx_qry, userid; 
	RETURN 'Records inserted into one landing table';
  ELSE
	RETURN 'No records inserted.';
  END IF;
END IF;

END
$_$;


ALTER FUNCTION web.create_landing_table_record(userid integer, request_type integer) OWNER TO ark_admin;

--
-- TOC entry 310 (class 1255 OID 25715)
-- Name: postsubmit_request(integer); Type: FUNCTION; Schema: web; Owner: ark_admin
--

CREATE FUNCTION postsubmit_request(drupal_user integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$


DECLARE

-------------------------------------------------------------------
-- DEFINE Variables Used in Function
-------------------------------------------------------------------
-- General function variables
qry text;
request integer;

default_record record;
default_selection boolean;
user_ndx integer;
own_ndx integer;

landing integer;
req_type integer;

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is the post-processing function for Form1 of the request form

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

---------
--STEPS--
---------


/* 1. Create a new request record in data.requests (Landing From 1 records 
   will always be new requests); Populate user_ndx,  own_ndx, req_type_ndx 
   and additional_info from form1 landing table */

qry := 'INSERT INTO data.data_requests(
            req_type_ndx, req_status_ndx, user_ndx, own_ndx, additional_info)
	SELECT req_type_ndx, 1, user_ndx, own_ndx_selected, additional_info
	  FROM web.landing_form1 
	  WHERE drupal_userid = ' || drupal_user || ';';
EXECUTE (qry);

/* Select and store req_ndx as variable */
qry := 'SELECT max(req_ndx)
	FROM data.data_requests;'; 
FOR request IN EXECUTE (qry) LOOP
END LOOP;

/* 2. Create initial log record for this req_ndx in table data.data_requests_log, 
   with event index 1 ("initial submit") and populate the log_timestamp with 
   submit_timestamp from form1 landing table */

qry := 'INSERT INTO data.data_requests_log(
            req_ndx, log_timestamp, log_event_ndx)
	SELECT ' || request || ', submit_timestamp, 1
	  FROM web.landing_form1
	  WHERE drupal_userid = ' || drupal_user || ';';
EXECUTE (qry);

/* 3. Create related record in data.data_requests_form1_content to capture 
   the default_selection field, the submitting drupal user and the potentially 
   modified user and entity info fields (to be processed later) */
qry := 'INSERT INTO data.data_requests_form1_content(
            req_ndx, default_selection, ownerentity_name, ownerentity_email, 
            ownerentity_phone, user_entity, user_email, user_phone, drupal_userid)
	SELECT ' || request || ', default_selection, ownerentity_name, ownerentity_email,
	     ownerentity_phone, user_entity, user_email, user_phone, drupal_userid
	  FROM web.landing_form1
	  WHERE drupal_userid = ' || drupal_user || ';';
EXECUTE (qry);

/* 4. Process default_selection submitted to determine whether or not to 
      change the default flag in the data.assoc_user_to_ownerentity table. 
      If the default_selection is false, no need to process, but if it's true, 
      update the default_user boolean in the data table to be true for the 
      user_ndx/own_ndx association matching that of the submitted form and false
      for any other associations with that user_ndx. */

qry := 'SELECT default_selection, user_ndx, own_ndx_selected
	FROM web.landing_form1
	WHERE drupal_userid = ' || drupal_user || ';';
FOR default_record IN EXECUTE (qry) 
LOOP
	default_selection = default_record.default_selection;
	user_ndx = default_record.user_ndx;
	own_ndx = default_record.own_ndx_selected; 

	IF default_selection IS TRUE THEN 
	
		-- Set all associations false for this user_ndx 
		qry := 'UPDATE data.assoc_user_to_ownerentity
			SET default_user = FALSE
			WHERE user_ndx = ' || user_ndx || ';';
		EXECUTE (qry);

		-- Set the new default user_ndx to owner_ndx association true
		qry := 'UPDATE data.assoc_user_to_ownerentity
			SET default_user = TRUE 
			WHERE user_ndx = ' || user_ndx || ' 
			   AND own_ndx = ' || own_ndx || ';';
		EXECUTE (qry);	

	ELSE
	END IF;

END LOOP;

/* 5. Process ownerentity_name, ownerentity_email, ownerentity_phone, user_entity, 
      user_email, and user_phone to determine if changes were submitted (compare to 
      existing values for own_ndx_selected or user_ndx);  if changes were submitted, 
      an alert email will be sent to div 2 with the info - system will not update 
      the values of record automatically. */

/* 6. Process other landing table(s), based on reqest type and contents of that form 
      sumbmission for the same landing_ndx, creating records in other data tables with 
      the same req_ndx as created in step 1 here. (see other landing table logic pages) */

/* Select and store landing_ndx as variable */
qry := 'SELECT landing_ndx
	FROM  web.landing_form1
        WHERE drupal_userid = ' || drupal_user || ';';
FOR landing IN EXECUTE (qry) LOOP
END LOOP;

/* Select and store req_type_ndx as variable */
qry := 'SELECT req_type_ndx
	FROM  web.landing_form1
        WHERE drupal_userid = ' || drupal_user || ';';
FOR req_type IN EXECUTE (qry) LOOP
END LOOP;

IF req_type = 1 THEN 

	/* //////////////////////////////////////////////////////////////
		req_type_ndx = 1 -- RESERVOIR RELEASE
	////////////////////////////////////////////////////////////// */

	qry := 'INSERT INTO data.data_releases(
		    req_ndx, start_timestamp, end_timestamp, fr_loc_ndx, deliv_loc_type_ndx, 
		    fr_wc_ndx, rel_amount, units_ndx, additional_notes)
		SELECT '|| request || ', 
		release_start_date + release_start_time AS start_timestamp, 
		(release_start_date + release_start_time) + (duration_days || ''days'')::interval AS end_timestamp, 
		loc_ndx, deliv_loc_type_ndx, wc_ndx, release_amount::real, unit_ndx, additional_notes 
		  FROM web.landing_request_reservoir
		  WHERE drupal_userid = ' || drupal_user || ' AND landing_ndx = ' || landing || ';';
	EXECUTE (qry);

ELSIF req_type = 2 THEN

	/* //////////////////////////////////////////////////////////////
		req_type_ndx = 2 -- EXCHANGE
	////////////////////////////////////////////////////////////// */

ELSIF req_type = 3 THEN

	/* //////////////////////////////////////////////////////////////
		req_type_ndx = 3 -- RESERVOIR ACCOUNT TRANSFER
	////////////////////////////////////////////////////////////// */

ELSIF req_type = 4 THEN

	/* //////////////////////////////////////////////////////////////
		req_type_ndx = 4 -- UPSTREAM CAPTURE
	////////////////////////////////////////////////////////////// */

ELSIF req_type = 5 THEN

	/* //////////////////////////////////////////////////////////////
		req_type_ndx = 5 -- CANCELLATION
	////////////////////////////////////////////////////////////// */

ELSE
END IF;

RETURN 42;

END
$$;


ALTER FUNCTION web.postsubmit_request(drupal_user integer) OWNER TO ark_admin;

--
-- TOC entry 299 (class 1255 OID 25308)
-- Name: reset_form1(); Type: FUNCTION; Schema: web; Owner: ark_admin
--

CREATE FUNCTION reset_form1() RETURNS text
    LANGUAGE plpgsql
    AS $$


DECLARE


BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is used to update the form1 landing table.

	This function runs when a user hits the next button on form 1.

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */
	

UPDATE web.landing_form1
   SET user_ndx=null, own_ndx_selected=null, default_selection=null, 
       ownerentity_name=null, ownerentity_email=null, ownerentity_phone=null, 
       additional_info=null, user_entity=null, user_email=null, user_phone=null,
       req_type_ndx=null;

RETURN 'Records Cleared';
END
$$;


ALTER FUNCTION web.reset_form1() OWNER TO ark_admin;

--
-- TOC entry 306 (class 1255 OID 25636)
-- Name: update_exchange_records(integer, json, text); Type: FUNCTION; Schema: web; Owner: ark_admin
--

CREATE FUNCTION update_exchange_records(userid integer, records json, recordtype text) RETURNS text
    LANGUAGE plpgsql
    AS $_$


DECLARE
check_qry text;
landing_ndx_qry bigint;
rec json;
rec2 json;

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is used to update the exchange landing table.

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

/* =================================================================================================	

STEPS
-------
1. Delete from JSON landing table
2. Insert JSON object into JSON landing table
3. Updating landing table for correct Drupal Userid with data from JSON landing table

================================================================================================= */

IF recordType = 'primary' THEN

	EXECUTE 'DELETE FROM web.landing_request_exchange_json WHERE drupal_userid = $1'
	USING userid;
	EXECUTE 'DELETE FROM web.landing_request_exchange_secondary_json WHERE drupal_userid = $1'
	USING userid;
	EXECUTE 'DELETE FROM web.landing_request_exchange_secondary WHERE drupal_userid = $1'
	USING userid;
	EXECUTE 'INSERT INTO web.landing_request_exchange_json (json_obj, drupal_userid) VALUES ($1,$2)'
	USING records,userid;

	UPDATE web.landing_request_exchange l SET 
		exchange_start_date = j.exchange_start_date, 
		exchange_start_time = j.exchange_start_time, 
		exchange_end_date = j.exchange_end_date,  
		exchange_end_time = j.exchange_end_time, 
		duration_days = j.duration_days, 
		exchange_rate = j.exchange_rate, 
		unit_ndx = j.unit_ndx, 
		to_deliv_loc_type_ndx = j.to_deliv_loc_type_ndx,
		to_loc_ndx = j.to_loc_ndx,
		to_wc_ndx = j.to_wc_ndx,
		to_own_ndx = j.to_own_ndx,
		from_deliv_loc_type_ndx = j.from_deliv_loc_type_ndx,
		from_loc_ndx = j.from_loc_ndx,
		from_wc_ndx = j.from_wc_ndx,
		from_own_ndx = j.from_own_ndx,
		additional_notes = j.additional_notes,	 
		drupal_userid = j.drupal_userid FROM (
	SELECT  (j.json_obj ->> 'exchange_start_date')::date AS exchange_start_date,
		(j.json_obj ->> 'exchange_start_time')::time without time zone AS exchange_start_time,
		(j.json_obj ->> 'exchange_end_date')::date AS exchange_end_date,
		(j.json_obj ->> 'exchange_end_time')::time without time zone AS exchange_end_time,
		j.json_obj ->> 'duration_days' AS duration_days,
		j.json_obj ->> 'exchange_rate' AS exchange_rate,
		(j.json_obj ->> 'unit_ndx')::integer AS unit_ndx,
		(j.json_obj ->> 'to_deliv_loc_type_ndx')::integer AS to_deliv_loc_type_ndx,
		(j.json_obj ->> 'to_loc_ndx')::integer AS to_loc_ndx,
		(j.json_obj ->> 'to_wc_ndx')::integer AS to_wc_ndx,
		(j.json_obj ->> 'to_own_ndx')::integer AS to_own_ndx,
		(j.json_obj ->> 'from_deliv_loc_type_ndx')::integer AS from_deliv_loc_type_ndx,
		(j.json_obj ->> 'from_loc_ndx')::integer AS from_loc_ndx,
		(j.json_obj ->> 'from_wc_ndx')::integer AS from_wc_ndx,
		(j.json_obj ->> 'from_own_ndx')::integer AS from_own_ndx,
		j.json_obj ->> 'additional_notes' AS additional_notes,	
		(j.json_obj ->> 'drupal_userid')::integer AS drupal_userid
	FROM web.landing_request_exchange_json j
	WHERE (j.json_obj ->> 'drupal_userid')::integer = userid ) j
	WHERE l.drupal_userid = j.drupal_userid::integer;

	RETURN 'Records Inserted';
ELSIF recordType = 'secondary' THEN
	EXECUTE 'DELETE FROM web.landing_request_exchange_secondary_json WHERE drupal_userid = $1'
	USING userid;
	
	FOR rec IN SELECT * FROM json_array_elements(records)
	LOOP
		EXECUTE 'INSERT INTO web.landing_request_exchange_secondary_json (json_obj,drupal_userid) VALUES ($1,$2)'
		USING rec,userid;
	END LOOP;

	EXECUTE 'DELETE FROM web.landing_request_exchange_secondary WHERE drupal_userid = $1'
	USING userid;

	SELECT landing_ndx INTO landing_ndx_qry FROM web.landing_form_1 WHERE drupal_userid = userid;

	FOR rec2 IN SELECT * FROM web.landing_request_exchange_secondary_json
	LOOP
		EXECUTE 'INSERT INTO web.landing_request_exchange_secondary (landing_ndx, from_loc_ndx, exchange_start_date, exchange_rate, drupal_userid) VALUES ($1,$2,$3,$4,$5)'
		USING landing_ndx_qry, (rec2 ->> 'from_loc_ndx')::integer, (rec2 ->> 'exchange_start_date')::date, rec2 ->> 'exchange_rate', userid;
	END LOOP;

	RETURN 'Records Inserted';
END IF;
END
$_$;


ALTER FUNCTION web.update_exchange_records(userid integer, records json, recordtype text) OWNER TO ark_admin;

--
-- TOC entry 296 (class 1255 OID 25257)
-- Name: update_form1_records(integer, json); Type: FUNCTION; Schema: web; Owner: ark_admin
--

CREATE FUNCTION update_form1_records(userid integer, records json) RETURNS text
    LANGUAGE plpgsql
    AS $_$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is used to update the form 1 landing table.

	This function runs when a user hits the next button on form 1.

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

/* =================================================================================================	

STEPS
-------
1. Delete from JSON landing table
2. Insert JSON object into JSON landing table
3. Updating landing table for correct Drupal Userid with data from JSON landing table

================================================================================================= */

EXECUTE 'DELETE FROM web.landing_form1_json WHERE drupal_userid = $1'
USING userid;
EXECUTE 'INSERT INTO web.landing_form1_json (json_obj,drupal_userid) VALUES ($1,$2)'
USING records,userid;

UPDATE web.landing_form1 l SET user_ndx = j.user_ndx, own_ndx_selected = j.own_ndx_selected, default_selection = j.default_selection,  ownerentity_name = j.ownerentity_name, ownerentity_email = j.ownerentity_email, ownerentity_phone = j.ownerentity_phone, additional_info = j.additional_info, user_entity = j.user_entity, user_email = j.user_email, user_phone = j.user_phone, drupal_userid = j.drupal_userid, req_type_ndx = j.req_type_ndx FROM (
SELECT  (j.json_obj ->> 'user_ndx')::integer AS user_ndx,
	(j.json_obj ->> 'own_ndx_selected')::integer AS own_ndx_selected,
	(j.json_obj ->> 'default_selection')::boolean AS default_selection,
	j.json_obj ->> 'ownerentity_name' AS ownerentity_name,
	j.json_obj ->> 'ownerentity_email' AS ownerentity_email,
	j.json_obj ->> 'ownerentity_phone' AS ownerentity_phone,
	j.json_obj ->> 'additional_info' AS additional_info,
	j.json_obj ->> 'user_entity' AS user_entity,
	j.json_obj ->> 'user_email' AS user_email,
	j.json_obj ->> 'user_phone' AS user_phone,
	(j.json_obj ->> 'drupal_userid')::integer AS drupal_userid,
	(j.json_obj ->> 'req_type_ndx')::integer AS req_type_ndx
FROM web.landing_form1_json j
WHERE (j.json_obj ->> 'drupal_userid')::integer = userid ) j
WHERE l.drupal_userid = j.drupal_userid::integer;

RETURN 'Records Inserted';
END
$_$;


ALTER FUNCTION web.update_form1_records(userid integer, records json) OWNER TO ark_admin;

--
-- TOC entry 295 (class 1255 OID 25415)
-- Name: update_res_release_records(integer, json); Type: FUNCTION; Schema: web; Owner: ark_admin
--

CREATE FUNCTION update_res_release_records(userid integer, records json) RETURNS text
    LANGUAGE plpgsql
    AS $_$


DECLARE

BEGIN
/* //////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

	This function is used to update the form 1 landing table.

	This function runs when a user hits the next button on form 1.

////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////// */

/* =================================================================================================	

STEPS
-------
1. Delete from JSON landing table
2. Insert JSON object into JSON landing table
3. Updating landing table for correct Drupal Userid with data from JSON landing table

================================================================================================= */

EXECUTE 'DELETE FROM web.landing_request_reservoir_json WHERE drupal_userid = $1'
USING userid;
EXECUTE 'INSERT INTO web.landing_request_reservoir_json (json_obj,drupal_userid) VALUES ($1,$2)'
USING records,userid;

UPDATE web.landing_request_reservoir l SET loc_ndx = j.loc_ndx, release_start_date = j.release_start_date, release_start_time = j.release_start_time,  deliv_loc_type_ndx = j.deliv_loc_type_ndx, release_amount = j.release_amount, unit_ndx = j.unit_ndx, duration_days = j.duration_days, wc_ndx = j.wc_ndx, additional_notes = j.additional_notes, drupal_userid = j.drupal_userid FROM (
SELECT  (j.json_obj ->> 'loc_ndx')::integer AS loc_ndx,
	(j.json_obj ->> 'release_start_date')::date AS release_start_date,
	(j.json_obj ->> 'release_start_time')::time without time zone AS release_start_time,
	(j.json_obj ->> 'deliv_loc_type_ndx')::integer AS deliv_loc_type_ndx,
	j.json_obj ->> 'release_amount' AS release_amount,
	(j.json_obj ->> 'unit_ndx')::integer AS unit_ndx,
	j.json_obj ->> 'duration_days' AS duration_days,
	(j.json_obj ->> 'wc_ndx')::integer AS wc_ndx,
	j.json_obj ->> 'additional_notes' AS additional_notes,
	(j.json_obj ->> 'drupal_userid')::integer AS drupal_userid
FROM web.landing_request_reservoir_json j
WHERE (j.json_obj ->> 'drupal_userid')::integer = userid ) j
WHERE l.drupal_userid = j.drupal_userid::integer;

RETURN 'Records Inserted';
END
$_$;


ALTER FUNCTION web.update_res_release_records(userid integer, records json) OWNER TO ark_admin;

SET search_path = archive, pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- TOC entry 228 (class 1259 OID 25108)
-- Name: landing_request_reservoir_log; Type: TABLE; Schema: archive; Owner: ark_admin
--

CREATE TABLE landing_request_reservoir_log (
    landing_ndx bigint,
    user_ndx integer,
    own_ndx_selected integer,
    default_selection boolean,
    ownerentity_name text,
    ownerentity_email text,
    ownerentity_phone text,
    additional_info text,
    user_entity text,
    user_email text,
    user_phone text,
    loc_ndx integer,
    release_start_date date,
    release_start_time time without time zone,
    deliv_loc_type_ndx integer,
    release_amount text,
    unit_ndx integer,
    duration_days text,
    wc_ndx integer,
    additional_notes text,
    submit_timestamp timestamp without time zone,
    drupal_userid integer
);


ALTER TABLE landing_request_reservoir_log OWNER TO ark_admin;

--
-- TOC entry 2578 (class 0 OID 0)
-- Dependencies: 228
-- Name: TABLE landing_request_reservoir_log; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON TABLE landing_request_reservoir_log IS 'Accumulated raw landing table records for data submitted from the Reservoir Releases Request form.';


--
-- TOC entry 2579 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.landing_ndx; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.landing_ndx IS 'auto generating table index';


--
-- TOC entry 2580 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.user_ndx; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.user_ndx IS 'index for system user submitting the form, keyed to [data].[list_users]';


--
-- TOC entry 2581 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.own_ndx_selected; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.own_ndx_selected IS 'index for ownerentity user submitting on behalf of, keyed to [data].[list_ownerentities]';


--
-- TOC entry 2582 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.default_selection; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.default_selection IS 'check-box for "make this my default selection" option; when true, update the appropriate user to entity assoc records.';


--
-- TOC entry 2583 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.ownerentity_name; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.ownerentity_name IS 'name for the own_ndx_selected (user may have edited this)';


--
-- TOC entry 2584 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.ownerentity_email; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.ownerentity_email IS 'email address for the own_ndx_selected (user may have edited this)';


--
-- TOC entry 2585 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.ownerentity_phone; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.ownerentity_phone IS 'phone number field for the own_ndx_selected (user may have edited this)';


--
-- TOC entry 2586 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.additional_info; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.additional_info IS 'additional info field (not required)';


--
-- TOC entry 2587 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.user_entity; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.user_entity IS 'ownerentity name associated with the system user submitting the form (user may have changed this)';


--
-- TOC entry 2588 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.user_email; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.user_email IS 'email address associated with the system user submitting the form (user may have changed this)';


--
-- TOC entry 2589 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.user_phone; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.user_phone IS 'primary contact phone # associated with the system user submitting the form (user may have changed this)';


--
-- TOC entry 2590 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.loc_ndx; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.loc_ndx IS 'Selected release from location, keyed to table [data].[list_locations]';


--
-- TOC entry 2591 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.release_start_date; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.release_start_date IS 'Specified release start date';


--
-- TOC entry 2592 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.release_start_time; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.release_start_time IS 'requested release time';


--
-- TOC entry 2593 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.deliv_loc_type_ndx; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.deliv_loc_type_ndx IS 'Delivery Location Type selection (At the reservoir or at the headgate), keyed to table [data].[list_delivery_loc_types]';


--
-- TOC entry 2594 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.release_amount; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.release_amount IS 'Requested release amount - this field should be numeric';


--
-- TOC entry 2595 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.unit_ndx; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.unit_ndx IS 'Selected units for release amount (cfs or af/day) keyed to table [data].[list_units]';


--
-- TOC entry 2596 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.duration_days; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.duration_days IS 'release duration requested in days (this field should be numeric)';


--
-- TOC entry 2597 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.wc_ndx; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.wc_ndx IS 'Selected Water Color for release (aka type of reservoir water) keyed to table [data].[list_water_colors]';


--
-- TOC entry 2598 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.additional_notes; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.additional_notes IS 'Additional notes added by user on the deliver request details page';


--
-- TOC entry 2599 (class 0 OID 0)
-- Dependencies: 228
-- Name: COLUMN landing_request_reservoir_log.drupal_userid; Type: COMMENT; Schema: archive; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir_log.drupal_userid IS 'drupal user submitting the form';


SET search_path = data, pg_catalog;

--
-- TOC entry 221 (class 1259 OID 16684)
-- Name: assoc_diversion_classes; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE assoc_diversion_classes (
    dc_ndx integer NOT NULL,
    loc_ndx integer,
    wc_ndx integer,
    own_ndx integer,
    calc_type_ndx integer,
    acctg_grp text,
    dc_wdid text,
    dc_source text,
    dc_fr_wdid text,
    dc_use text,
    dc_type text,
    dc_group_wdid text,
    dc_to_wdid text,
    dc_obs boolean
);


ALTER TABLE assoc_diversion_classes OWNER TO ark_admin;

--
-- TOC entry 220 (class 1259 OID 16682)
-- Name: assoc_diversion_classes_dc_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE assoc_diversion_classes_dc_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE assoc_diversion_classes_dc_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2600 (class 0 OID 0)
-- Dependencies: 220
-- Name: assoc_diversion_classes_dc_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE assoc_diversion_classes_dc_ndx_seq OWNED BY assoc_diversion_classes.dc_ndx;


--
-- TOC entry 197 (class 1259 OID 16541)
-- Name: assoc_loc_to_water_colors; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE assoc_loc_to_water_colors (
    loc_ndx integer NOT NULL,
    wc_ndx integer NOT NULL,
    notes text
);


ALTER TABLE assoc_loc_to_water_colors OWNER TO ark_admin;

--
-- TOC entry 259 (class 1259 OID 25485)
-- Name: assoc_request_to_landing_tables; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE assoc_request_to_landing_tables (
    req_type_ndx integer NOT NULL,
    primary_landing_table_ndx integer NOT NULL,
    notes text,
    secondary_landing_table_ndx integer
);


ALTER TABLE assoc_request_to_landing_tables OWNER TO ark_admin;

--
-- TOC entry 196 (class 1259 OID 16535)
-- Name: assoc_user_to_loc; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE assoc_user_to_loc (
    user_ndx integer NOT NULL,
    loc_ndx integer NOT NULL,
    notes text
);


ALTER TABLE assoc_user_to_loc OWNER TO ark_admin;

--
-- TOC entry 222 (class 1259 OID 17118)
-- Name: assoc_user_to_ownerentity; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE assoc_user_to_ownerentity (
    user_ndx integer NOT NULL,
    own_ndx integer NOT NULL,
    notes text,
    default_user boolean,
    form1_display boolean DEFAULT true,
    self boolean
);


ALTER TABLE assoc_user_to_ownerentity OWNER TO ark_admin;

--
-- TOC entry 198 (class 1259 OID 16564)
-- Name: assoc_user_to_water_color; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE assoc_user_to_water_color (
    user_ndx integer NOT NULL,
    wc_ndx integer NOT NULL,
    notes text
);


ALTER TABLE assoc_user_to_water_color OWNER TO ark_admin;

--
-- TOC entry 206 (class 1259 OID 16601)
-- Name: data_assoc_exch_from; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE data_assoc_exch_from (
    req_ndx integer,
    exch_fr_ndx integer NOT NULL,
    fr_loc_ndx integer,
    fr_deliv_loc_type_ndx integer,
    fr_water_color_ndx integer,
    fr_own_ndx integer
);


ALTER TABLE data_assoc_exch_from OWNER TO ark_admin;

--
-- TOC entry 205 (class 1259 OID 16599)
-- Name: data_assoc_exch_from_exch_fr_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE data_assoc_exch_from_exch_fr_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE data_assoc_exch_from_exch_fr_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2605 (class 0 OID 0)
-- Dependencies: 205
-- Name: data_assoc_exch_from_exch_fr_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE data_assoc_exch_from_exch_fr_ndx_seq OWNED BY data_assoc_exch_from.exch_fr_ndx;


--
-- TOC entry 204 (class 1259 OID 16593)
-- Name: data_assoc_exch_to; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE data_assoc_exch_to (
    req_ndx integer,
    exch_to_ndx integer NOT NULL,
    to_loc_ndx integer,
    to_deliv_loc_type_ndx integer,
    to_water_color_ndx integer,
    to_own_ndx integer
);


ALTER TABLE data_assoc_exch_to OWNER TO ark_admin;

--
-- TOC entry 203 (class 1259 OID 16591)
-- Name: data_assoc_exch_to_exch_to_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE data_assoc_exch_to_exch_to_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE data_assoc_exch_to_exch_to_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2606 (class 0 OID 0)
-- Dependencies: 203
-- Name: data_assoc_exch_to_exch_to_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE data_assoc_exch_to_exch_to_ndx_seq OWNED BY data_assoc_exch_to.exch_to_ndx;


--
-- TOC entry 213 (class 1259 OID 16631)
-- Name: data_assoc_transfers_to; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE data_assoc_transfers_to (
    req_ndx integer,
    tran_to_ndx integer NOT NULL,
    to_own_ndx integer,
    to_wc_ndx integer,
    tran_amount real,
    units_ndx integer
);


ALTER TABLE data_assoc_transfers_to OWNER TO ark_admin;

--
-- TOC entry 212 (class 1259 OID 16629)
-- Name: data_assoc_transfers_to_tran_to_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE data_assoc_transfers_to_tran_to_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE data_assoc_transfers_to_tran_to_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2607 (class 0 OID 0)
-- Dependencies: 212
-- Name: data_assoc_transfers_to_tran_to_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE data_assoc_transfers_to_tran_to_ndx_seq OWNED BY data_assoc_transfers_to.tran_to_ndx;


--
-- TOC entry 210 (class 1259 OID 16617)
-- Name: data_cancellations; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE data_cancellations (
    req_ndx integer,
    cancel_datetime timestamp without time zone NOT NULL,
    cancel_by_nxd integer,
    cancel_reason_ndx integer,
    cancel_notes text,
    user_ndx integer
);


ALTER TABLE data_cancellations OWNER TO ark_admin;

--
-- TOC entry 202 (class 1259 OID 16585)
-- Name: data_exchanges; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE data_exchanges (
    req_ndx integer NOT NULL,
    start_datetime timestamp without time zone,
    end_datetime timestamp without time zone,
    exch_rate real,
    units_ndx integer,
    exch_notes text
);


ALTER TABLE data_exchanges OWNER TO ark_admin;

--
-- TOC entry 209 (class 1259 OID 16611)
-- Name: data_rel_modified_log; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE data_rel_modified_log (
    log_req_ndx integer,
    log_modified_field text NOT NULL,
    log_modified_notes text,
    req_ndx integer NOT NULL,
    start_datetime timestamp without time zone NOT NULL,
    end_datetime timestamp without time zone NOT NULL,
    deliv_loc_type_ndx integer NOT NULL,
    rel_amount real NOT NULL
);


ALTER TABLE data_rel_modified_log OWNER TO ark_admin;

--
-- TOC entry 201 (class 1259 OID 16582)
-- Name: data_releases; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE data_releases (
    req_ndx integer NOT NULL,
    start_timestamp timestamp without time zone NOT NULL,
    end_timestamp timestamp without time zone NOT NULL,
    fr_loc_ndx integer NOT NULL,
    deliv_loc_type_ndx integer NOT NULL,
    fr_wc_ndx integer NOT NULL,
    rel_amount real NOT NULL,
    units_ndx integer NOT NULL,
    additional_notes text
);


ALTER TABLE data_releases OWNER TO ark_admin;

--
-- TOC entry 208 (class 1259 OID 16607)
-- Name: data_requests; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE data_requests (
    req_ndx integer NOT NULL,
    req_type_ndx integer,
    req_status_ndx integer,
    user_ndx integer,
    own_ndx integer,
    additional_info text
);


ALTER TABLE data_requests OWNER TO ark_admin;

--
-- TOC entry 277 (class 1259 OID 25661)
-- Name: data_requests_form1_content; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE data_requests_form1_content (
    req_ndx integer NOT NULL,
    default_selection boolean,
    ownerentity_name text,
    ownerentity_email text,
    ownerentity_phone text,
    user_entity text,
    user_email text,
    user_phone text,
    drupal_userid integer
);


ALTER TABLE data_requests_form1_content OWNER TO ark_admin;

--
-- TOC entry 200 (class 1259 OID 16573)
-- Name: data_requests_log; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE data_requests_log (
    req_ndx integer,
    log_req_ndx integer NOT NULL,
    log_timestamp timestamp without time zone,
    log_event_ndx integer,
    log_notes text
);


ALTER TABLE data_requests_log OWNER TO ark_admin;

--
-- TOC entry 199 (class 1259 OID 16571)
-- Name: data_requests_log_log_req_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE data_requests_log_log_req_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE data_requests_log_log_req_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2608 (class 0 OID 0)
-- Dependencies: 199
-- Name: data_requests_log_log_req_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE data_requests_log_log_req_ndx_seq OWNED BY data_requests_log.log_req_ndx;


--
-- TOC entry 207 (class 1259 OID 16605)
-- Name: data_requests_req_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE data_requests_req_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE data_requests_req_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2609 (class 0 OID 0)
-- Dependencies: 207
-- Name: data_requests_req_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE data_requests_req_ndx_seq OWNED BY data_requests.req_ndx;


--
-- TOC entry 211 (class 1259 OID 16623)
-- Name: data_transfers; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE data_transfers (
    fr_own_ndx integer,
    req_ndx integer NOT NULL,
    fr_wc_ndx integer,
    tran_date date,
    tran_notes text
);


ALTER TABLE data_transfers OWNER TO ark_admin;

--
-- TOC entry 214 (class 1259 OID 16637)
-- Name: data_uscapture; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE data_uscapture (
    req_ndx integer NOT NULL,
    fr_loc_ndx integer,
    to_loc_ndx integer,
    wc_ndx integer,
    cap_by_own_ndx integer,
    cap_amount real,
    units_ndx integer,
    cap_duration_days integer,
    cap_notes text
);


ALTER TABLE data_uscapture OWNER TO ark_admin;

--
-- TOC entry 219 (class 1259 OID 16673)
-- Name: list_cancelled_by; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_cancelled_by (
    cancel_by_ndx integer NOT NULL,
    cancel_by_descrip text NOT NULL
);


ALTER TABLE list_cancelled_by OWNER TO ark_admin;

--
-- TOC entry 218 (class 1259 OID 16671)
-- Name: list_cancelled_by_cancel_by_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_cancelled_by_cancel_by_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_cancelled_by_cancel_by_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2610 (class 0 OID 0)
-- Dependencies: 218
-- Name: list_cancelled_by_cancel_by_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_cancelled_by_cancel_by_ndx_seq OWNED BY list_cancelled_by.cancel_by_ndx;


--
-- TOC entry 217 (class 1259 OID 16662)
-- Name: list_cancelled_reasons; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_cancelled_reasons (
    cancel_reason_ndx integer NOT NULL,
    cancel_reason_descrip text
);


ALTER TABLE list_cancelled_reasons OWNER TO ark_admin;

--
-- TOC entry 216 (class 1259 OID 16660)
-- Name: list_cancelled_reasons_cancel_reason_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_cancelled_reasons_cancel_reason_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_cancelled_reasons_cancel_reason_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2611 (class 0 OID 0)
-- Dependencies: 216
-- Name: list_cancelled_reasons_cancel_reason_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_cancelled_reasons_cancel_reason_ndx_seq OWNED BY list_cancelled_reasons.cancel_reason_ndx;


--
-- TOC entry 191 (class 1259 OID 16495)
-- Name: list_delivery_loc_types; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_delivery_loc_types (
    deliv_loc_type_ndx integer NOT NULL,
    deliv_loc_type_descrip text,
    dd_exch_to boolean,
    dd_exch_from boolean,
    dd_release boolean,
    display_order integer
);


ALTER TABLE list_delivery_loc_types OWNER TO ark_admin;

--
-- TOC entry 190 (class 1259 OID 16493)
-- Name: list_delivery_loc_types_deliv_loc_type_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_delivery_loc_types_deliv_loc_type_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_delivery_loc_types_deliv_loc_type_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2612 (class 0 OID 0)
-- Dependencies: 190
-- Name: list_delivery_loc_types_deliv_loc_type_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_delivery_loc_types_deliv_loc_type_ndx_seq OWNED BY list_delivery_loc_types.deliv_loc_type_ndx;


--
-- TOC entry 215 (class 1259 OID 16643)
-- Name: list_drupal_users; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_drupal_users (
    drupal_userid integer NOT NULL,
    drupal_user_name text NOT NULL,
    drupal_account_email text NOT NULL,
    notes text
);


ALTER TABLE list_drupal_users OWNER TO ark_admin;

--
-- TOC entry 179 (class 1259 OID 16420)
-- Name: list_locations; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_locations (
    loc_ndx integer NOT NULL,
    loc_name text,
    loc_wdid text,
    loc_descrip text,
    loc_lon double precision,
    loc_lat double precision,
    dd_release boolean,
    dd_exch_to boolean,
    dd_exch_from boolean,
    dd_capture_from boolean,
    display_order integer
);


ALTER TABLE list_locations OWNER TO ark_admin;

--
-- TOC entry 178 (class 1259 OID 16418)
-- Name: list_locations_loc_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_locations_loc_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_locations_loc_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2614 (class 0 OID 0)
-- Dependencies: 178
-- Name: list_locations_loc_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_locations_loc_ndx_seq OWNED BY list_locations.loc_ndx;


--
-- TOC entry 189 (class 1259 OID 16486)
-- Name: list_log_events; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_log_events (
    log_event_ndx integer NOT NULL,
    log_event_descrip text NOT NULL
);


ALTER TABLE list_log_events OWNER TO ark_admin;

--
-- TOC entry 188 (class 1259 OID 16484)
-- Name: list_log_events_log_event_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_log_events_log_event_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_log_events_log_event_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2616 (class 0 OID 0)
-- Dependencies: 188
-- Name: list_log_events_log_event_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_log_events_log_event_ndx_seq OWNED BY list_log_events.log_event_ndx;


--
-- TOC entry 181 (class 1259 OID 16438)
-- Name: list_ownerentities; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_ownerentities (
    own_ndx integer NOT NULL,
    own_name text,
    own_descrip text,
    dd_transfer_from boolean,
    dd_transfer_to boolean,
    own_email text,
    own_phone text
);


ALTER TABLE list_ownerentities OWNER TO ark_admin;

--
-- TOC entry 180 (class 1259 OID 16436)
-- Name: list_ownerentities_own_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_ownerentities_own_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_ownerentities_own_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2618 (class 0 OID 0)
-- Dependencies: 180
-- Name: list_ownerentities_own_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_ownerentities_own_ndx_seq OWNED BY list_ownerentities.own_ndx;


--
-- TOC entry 258 (class 1259 OID 25476)
-- Name: list_request_landing_tables; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_request_landing_tables (
    landing_table_ndx integer NOT NULL,
    landing_table_descrip text NOT NULL,
    notes text
);


ALTER TABLE list_request_landing_tables OWNER TO ark_admin;

--
-- TOC entry 257 (class 1259 OID 25474)
-- Name: list_request_landing_tables_landing_table_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_request_landing_tables_landing_table_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_request_landing_tables_landing_table_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2620 (class 0 OID 0)
-- Dependencies: 257
-- Name: list_request_landing_tables_landing_table_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_request_landing_tables_landing_table_ndx_seq OWNED BY list_request_landing_tables.landing_table_ndx;


--
-- TOC entry 185 (class 1259 OID 16465)
-- Name: list_request_status; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_request_status (
    req_status_ndx integer NOT NULL,
    req_status_descrip text NOT NULL
);


ALTER TABLE list_request_status OWNER TO ark_admin;

--
-- TOC entry 184 (class 1259 OID 16463)
-- Name: list_request_status_req_status_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_request_status_req_status_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_request_status_req_status_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2621 (class 0 OID 0)
-- Dependencies: 184
-- Name: list_request_status_req_status_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_request_status_req_status_ndx_seq OWNED BY list_request_status.req_status_ndx;


--
-- TOC entry 193 (class 1259 OID 16504)
-- Name: list_request_types; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_request_types (
    req_type_ndx integer NOT NULL,
    req_type_descrip text NOT NULL,
    notes text,
    display_order integer
);


ALTER TABLE list_request_types OWNER TO ark_admin;

--
-- TOC entry 192 (class 1259 OID 16502)
-- Name: list_requests_types_req_type_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_requests_types_req_type_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_requests_types_req_type_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2622 (class 0 OID 0)
-- Dependencies: 192
-- Name: list_requests_types_req_type_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_requests_types_req_type_ndx_seq OWNED BY list_request_types.req_type_ndx;


--
-- TOC entry 195 (class 1259 OID 16515)
-- Name: list_units; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_units (
    unit_ndx integer NOT NULL,
    unit_abbrev text,
    unit_descrip text
);


ALTER TABLE list_units OWNER TO ark_admin;

--
-- TOC entry 194 (class 1259 OID 16513)
-- Name: list_units_unit_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_units_unit_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_units_unit_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2623 (class 0 OID 0)
-- Dependencies: 194
-- Name: list_units_unit_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_units_unit_ndx_seq OWNED BY list_units.unit_ndx;


--
-- TOC entry 177 (class 1259 OID 16411)
-- Name: list_users; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_users (
    user_ndx integer NOT NULL,
    user_name text,
    own_ndx integer,
    user_email text,
    user_phone_primary text,
    drupal_userid integer,
    drupal_name text
);


ALTER TABLE list_users OWNER TO ark_admin;

--
-- TOC entry 176 (class 1259 OID 16409)
-- Name: list_user_user_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_user_user_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_user_user_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2625 (class 0 OID 0)
-- Dependencies: 176
-- Name: list_user_user_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_user_user_ndx_seq OWNED BY list_users.user_ndx;


--
-- TOC entry 187 (class 1259 OID 16474)
-- Name: list_water_colors; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_water_colors (
    wc_ndx integer NOT NULL,
    wc_name text,
    wc_descrip text,
    dd_release boolean,
    dd_exch_to boolean,
    dd_exch_from boolean,
    dd_transfer_from boolean,
    dd_transfer_to boolean,
    dd_capture_from boolean,
    display_order integer
);


ALTER TABLE list_water_colors OWNER TO ark_admin;

--
-- TOC entry 186 (class 1259 OID 16472)
-- Name: list_water_colors_wc_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_water_colors_wc_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_water_colors_wc_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2627 (class 0 OID 0)
-- Dependencies: 186
-- Name: list_water_colors_wc_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_water_colors_wc_ndx_seq OWNED BY list_water_colors.wc_ndx;


--
-- TOC entry 183 (class 1259 OID 16447)
-- Name: list_wc_calc_types; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE list_wc_calc_types (
    calc_type_ndx integer NOT NULL,
    calc_type_descrip text NOT NULL
);


ALTER TABLE list_wc_calc_types OWNER TO ark_admin;

--
-- TOC entry 182 (class 1259 OID 16445)
-- Name: list_wc_calc_types_calc_type_ndx_seq; Type: SEQUENCE; Schema: data; Owner: ark_admin
--

CREATE SEQUENCE list_wc_calc_types_calc_type_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE list_wc_calc_types_calc_type_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2629 (class 0 OID 0)
-- Dependencies: 182
-- Name: list_wc_calc_types_calc_type_ndx_seq; Type: SEQUENCE OWNED BY; Schema: data; Owner: ark_admin
--

ALTER SEQUENCE list_wc_calc_types_calc_type_ndx_seq OWNED BY list_wc_calc_types.calc_type_ndx;


--
-- TOC entry 223 (class 1259 OID 25039)
-- Name: test_list_users; Type: TABLE; Schema: data; Owner: ark_admin
--

CREATE TABLE test_list_users (
    username text NOT NULL,
    email text,
    drupal_userid integer
);


ALTER TABLE test_list_users OWNER TO ark_admin;

SET search_path = tools, pg_catalog;

--
-- TOC entry 241 (class 1259 OID 25258)
-- Name: data_users_01; Type: VIEW; Schema: tools; Owner: ark_admin
--

CREATE VIEW data_users_01 AS
 SELECT u.user_ndx,
    u.own_ndx,
    u.user_name,
    o.own_name AS associated_entity,
    u.drupal_userid
   FROM (data.list_users u
     JOIN data.list_ownerentities o USING (own_ndx));


ALTER TABLE data_users_01 OWNER TO ark_admin;

--
-- TOC entry 253 (class 1259 OID 25426)
-- Name: data_users_02_entities; Type: VIEW; Schema: tools; Owner: ark_admin
--

CREATE VIEW data_users_02_entities AS
 SELECT u.user_ndx,
    (('<ul><li>'::text || string_agg(o2.own_name, '</li><li>'::text)) || '</li></ul>'::text) AS may_submit_on_behalf_of
   FROM ((data.list_users u
     LEFT JOIN ( SELECT assoc_user_to_ownerentity.user_ndx,
            assoc_user_to_ownerentity.own_ndx AS own_ndx_2
           FROM data.assoc_user_to_ownerentity
          WHERE assoc_user_to_ownerentity.form1_display) oe USING (user_ndx))
     JOIN ( SELECT list_ownerentities.own_ndx AS own_ndx_2,
            list_ownerentities.own_name
           FROM data.list_ownerentities) o2 USING (own_ndx_2))
  GROUP BY u.user_ndx;


ALTER TABLE data_users_02_entities OWNER TO ark_admin;

--
-- TOC entry 252 (class 1259 OID 25421)
-- Name: data_users_03_locations; Type: VIEW; Schema: tools; Owner: ark_admin
--

CREATE VIEW data_users_03_locations AS
 SELECT u.user_ndx,
    (('<ul><li>'::text || string_agg(ul.loc_name, '</li><li>'::text)) || '</li></ul>'::text) AS exchange_locations
   FROM (data.list_users u
     LEFT JOIN ( SELECT assoc_user_to_loc.user_ndx,
            assoc_user_to_loc.loc_ndx,
            l.loc_name
           FROM (data.assoc_user_to_loc
             JOIN data.list_locations l USING (loc_ndx))) ul USING (user_ndx))
  GROUP BY u.user_ndx;


ALTER TABLE data_users_03_locations OWNER TO ark_admin;

--
-- TOC entry 251 (class 1259 OID 25416)
-- Name: data_users_04_watercolors; Type: VIEW; Schema: tools; Owner: ark_admin
--

CREATE VIEW data_users_04_watercolors AS
 SELECT u.user_ndx,
    (('<ul><li>'::text || string_agg(uw.wc_name, '</li><li>'::text)) || '</li></ul>'::text) AS watercolor_locations
   FROM (data.list_users u
     LEFT JOIN ( SELECT assoc_user_to_water_color.user_ndx,
            assoc_user_to_water_color.wc_ndx,
            l.wc_name
           FROM (data.assoc_user_to_water_color
             JOIN data.list_water_colors l USING (wc_ndx))) uw USING (user_ndx))
  GROUP BY u.user_ndx;


ALTER TABLE data_users_04_watercolors OWNER TO ark_admin;

--
-- TOC entry 254 (class 1259 OID 25431)
-- Name: data_users_associations_display_gviz; Type: VIEW; Schema: tools; Owner: ark_admin
--

CREATE VIEW data_users_associations_display_gviz AS
 SELECT u.user_ndx,
    u.own_ndx,
    u.user_name,
    u.associated_entity,
    e.may_submit_on_behalf_of,
    '<button><a href="data_admin_edit_users_entities">Edit Entities</a></button>'::text AS edit_entities,
    l.exchange_locations,
    '<button><a href="data_admin_edit_users_locations">Edit Locations</a></button>'::text AS edit_locations,
    w.watercolor_locations,
    '<button><a href="data_admin_edit_users_watercolors">Edit Water Types</a></button>'::text AS edit_watercolors,
    u.drupal_userid
   FROM (((data_users_01 u
     LEFT JOIN data_users_02_entities e USING (user_ndx))
     LEFT JOIN data_users_03_locations l USING (user_ndx))
     LEFT JOIN data_users_04_watercolors w USING (user_ndx))
  ORDER BY u.user_name;


ALTER TABLE data_users_associations_display_gviz OWNER TO ark_admin;

--
-- TOC entry 267 (class 1259 OID 25578)
-- Name: dd_locations; Type: VIEW; Schema: tools; Owner: ark_admin
--

CREATE VIEW dd_locations AS
 SELECT l.loc_ndx,
    l.loc_name
   FROM data.list_locations l
  ORDER BY l.loc_name;


ALTER TABLE dd_locations OWNER TO ark_admin;

--
-- TOC entry 245 (class 1259 OID 25329)
-- Name: dd_users; Type: VIEW; Schema: tools; Owner: ark_admin
--

CREATE VIEW dd_users AS
 SELECT u.user_ndx,
    u.user_name,
    u.drupal_name AS system_name,
    u.user_email
   FROM data.list_users u
  ORDER BY u.user_name;


ALTER TABLE dd_users OWNER TO ark_admin;

--
-- TOC entry 269 (class 1259 OID 25589)
-- Name: egrid_assoc_locations_and_water_colors; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE egrid_assoc_locations_and_water_colors (
    loc_ndx integer,
    wc_ndx integer,
    wc_name text,
    assoc_true boolean
);


ALTER TABLE egrid_assoc_locations_and_water_colors OWNER TO ark_admin;

--
-- TOC entry 278 (class 1259 OID 25678)
-- Name: egrid_assoc_triple_users_locs_wcs; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE egrid_assoc_triple_users_locs_wcs (
    user_ndx integer,
    loc_name text,
    wc_ndx integer,
    wc_name text,
    assoc_true boolean
);


ALTER TABLE egrid_assoc_triple_users_locs_wcs OWNER TO ark_admin;

--
-- TOC entry 272 (class 1259 OID 25606)
-- Name: egrid_assoc_users_and_entities; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE egrid_assoc_users_and_entities (
    drupal_userid integer,
    user_ndx integer,
    own_ndx integer,
    own_name text,
    self boolean,
    assoc_true boolean,
    default_user boolean,
    form1_display boolean
);


ALTER TABLE egrid_assoc_users_and_entities OWNER TO ark_admin;

--
-- TOC entry 268 (class 1259 OID 25582)
-- Name: fetchit_landing_selected_loc_for_wc_assoc; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE fetchit_landing_selected_loc_for_wc_assoc (
    loc_ndx integer
);


ALTER TABLE fetchit_landing_selected_loc_for_wc_assoc OWNER TO ark_admin;

--
-- TOC entry 270 (class 1259 OID 25595)
-- Name: egrid_build_assoc_locations_and_water_colors; Type: VIEW; Schema: tools; Owner: ark_admin
--

CREATE VIEW egrid_build_assoc_locations_and_water_colors AS
 SELECT f.loc_ndx,
    l.wc_ndx,
    l.wc_name,
        CASE
            WHEN (a.loc_ndx IS NOT NULL) THEN true
            ELSE false
        END AS assoc_true
   FROM ((data.list_water_colors l
     CROSS JOIN fetchit_landing_selected_loc_for_wc_assoc f)
     LEFT JOIN data.assoc_loc_to_water_colors a USING (wc_ndx, loc_ndx))
  ORDER BY
        CASE
            WHEN (a.loc_ndx IS NOT NULL) THEN true
            ELSE false
        END DESC, l.wc_name;


ALTER TABLE egrid_build_assoc_locations_and_water_colors OWNER TO ark_admin;

--
-- TOC entry 246 (class 1259 OID 25344)
-- Name: fetchit_landing_selected_user_selectall; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE fetchit_landing_selected_user_selectall (
    selectall_flag boolean NOT NULL,
    drupal_userid integer NOT NULL
);


ALTER TABLE fetchit_landing_selected_user_selectall OWNER TO ark_admin;

--
-- TOC entry 249 (class 1259 OID 25400)
-- Name: fetchit_landing_selected_user_selectnone; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE fetchit_landing_selected_user_selectnone (
    selectnone_flag boolean NOT NULL,
    drupal_userid integer NOT NULL
);


ALTER TABLE fetchit_landing_selected_user_selectnone OWNER TO ark_admin;

--
-- TOC entry 247 (class 1259 OID 25361)
-- Name: fetchit_landing_selected_user_to_manage; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE fetchit_landing_selected_user_to_manage (
    user_ndx integer NOT NULL,
    drupal_userid integer NOT NULL,
    submit_timestamp timestamp without time zone DEFAULT now()
);


ALTER TABLE fetchit_landing_selected_user_to_manage OWNER TO ark_admin;

--
-- TOC entry 250 (class 1259 OID 25405)
-- Name: fetchit_landing_user_to_manage_last_submit; Type: VIEW; Schema: tools; Owner: ark_admin
--

CREATE VIEW fetchit_landing_user_to_manage_last_submit AS
 SELECT f1.user_ndx,
    f1.drupal_userid,
    f2.selectall_flag,
    f3.selectnone_flag,
    f1.submit_timestamp
   FROM (((fetchit_landing_selected_user_to_manage f1
     JOIN fetchit_landing_selected_user_selectall f2 USING (drupal_userid))
     JOIN fetchit_landing_selected_user_selectnone f3 USING (drupal_userid))
     JOIN ( SELECT max(t.submit_timestamp) AS submit_timestamp
           FROM fetchit_landing_selected_user_to_manage t) f4 USING (submit_timestamp));


ALTER TABLE fetchit_landing_user_to_manage_last_submit OWNER TO ark_admin;

--
-- TOC entry 271 (class 1259 OID 25601)
-- Name: egrid_build_assoc_users_and_entities; Type: VIEW; Schema: tools; Owner: ark_admin
--

CREATE VIEW egrid_build_assoc_users_and_entities AS
 SELECT f.drupal_userid,
    f.user_ndx,
    e.own_ndx,
    e.own_name,
    uo.self,
        CASE
            WHEN (uo.user_ndx IS NOT NULL) THEN true
            ELSE false
        END AS assoc_true,
        CASE
            WHEN (uo.user_ndx IS NULL) THEN false
            ELSE uo.default_user
        END AS default_user,
    uo.form1_display
   FROM ((fetchit_landing_user_to_manage_last_submit f
     CROSS JOIN data.list_ownerentities e)
     LEFT JOIN data.assoc_user_to_ownerentity uo USING (user_ndx, own_ndx))
  ORDER BY f.drupal_userid, f.user_ndx, uo.self,
        CASE
            WHEN (uo.user_ndx IS NULL) THEN false
            ELSE uo.default_user
        END DESC,
        CASE
            WHEN (uo.user_ndx IS NOT NULL) THEN true
            ELSE false
        END DESC, e.own_name;


ALTER TABLE egrid_build_assoc_users_and_entities OWNER TO ark_admin;

--
-- TOC entry 262 (class 1259 OID 25544)
-- Name: egrid_list_locations_add_new; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE egrid_list_locations_add_new (
    loc_name text,
    loc_wdid text,
    dd_release boolean,
    dd_exch_to boolean,
    dd_exch_from boolean,
    dd_capture_from boolean,
    display_order integer
);


ALTER TABLE egrid_list_locations_add_new OWNER TO ark_admin;

--
-- TOC entry 264 (class 1259 OID 25556)
-- Name: egrid_list_locations_edit_delete; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE egrid_list_locations_edit_delete (
    loc_ndx integer,
    loc_name text,
    loc_wdid text,
    dd_release boolean,
    dd_exch_to boolean,
    dd_exch_from boolean,
    dd_capture_from boolean,
    display_order integer,
    delete_bool boolean
);


ALTER TABLE egrid_list_locations_edit_delete OWNER TO ark_admin;

--
-- TOC entry 261 (class 1259 OID 25528)
-- Name: egrid_list_ownerentities_add_new; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE egrid_list_ownerentities_add_new (
    own_name text,
    dd_transfer_from boolean,
    dd_transfer_to boolean,
    own_email text,
    own_phone text
);


ALTER TABLE egrid_list_ownerentities_add_new OWNER TO ark_admin;

--
-- TOC entry 263 (class 1259 OID 25550)
-- Name: egrid_list_ownerentities_edit_delete; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE egrid_list_ownerentities_edit_delete (
    own_ndx integer,
    own_name text,
    dd_transfer_from boolean,
    dd_transfer_to boolean,
    own_email text,
    own_phone text,
    delete_bool boolean
);


ALTER TABLE egrid_list_ownerentities_edit_delete OWNER TO ark_admin;

--
-- TOC entry 266 (class 1259 OID 25568)
-- Name: egrid_list_water_colors_add_new; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE egrid_list_water_colors_add_new (
    wc_name text,
    dd_release boolean,
    dd_exch_to boolean,
    dd_exch_from boolean,
    dd_transfer_from boolean,
    dd_transfer_to boolean,
    dd_capture_from boolean,
    display_order integer
);


ALTER TABLE egrid_list_water_colors_add_new OWNER TO ark_admin;

--
-- TOC entry 265 (class 1259 OID 25562)
-- Name: egrid_list_water_colors_edit_delete; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE egrid_list_water_colors_edit_delete (
    wc_ndx integer,
    wc_name text,
    dd_release boolean,
    dd_exch_to boolean,
    dd_exch_from boolean,
    dd_transfer_from boolean,
    dd_transfer_to boolean,
    dd_capture_from boolean,
    display_order integer,
    delete_bool boolean
);


ALTER TABLE egrid_list_water_colors_edit_delete OWNER TO ark_admin;

--
-- TOC entry 274 (class 1259 OID 25633)
-- Name: fetchit_landing_selected_loc_for_user_wc_triple_assoc; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE fetchit_landing_selected_loc_for_user_wc_triple_assoc (
    loc_ndx integer
);


ALTER TABLE fetchit_landing_selected_loc_for_user_wc_triple_assoc OWNER TO ark_admin;

--
-- TOC entry 280 (class 1259 OID 25698)
-- Name: fetchit_landing_selected_wc_for_user_loc_triple_assoc; Type: TABLE; Schema: tools; Owner: ark_admin
--

CREATE TABLE fetchit_landing_selected_wc_for_user_loc_triple_assoc (
    wc_ndx integer
);


ALTER TABLE fetchit_landing_selected_wc_for_user_loc_triple_assoc OWNER TO ark_admin;

--
-- TOC entry 279 (class 1259 OID 25689)
-- Name: table_display_build_assoc_triple_users_locs_wcs_prep; Type: VIEW; Schema: tools; Owner: ark_admin
--

CREATE VIEW table_display_build_assoc_triple_users_locs_wcs_prep AS
 SELECT f.user_ndx,
    u.user_name,
    string_agg((ul.loc_ndx)::text, ', '::text ORDER BY l.loc_name) AS loc_ndx,
    string_agg(l.loc_name, ', '::text ORDER BY l.loc_name) AS loc_name,
    lwc.wc_ndx,
    uwc.wc_ndx AS assoc_wc_ndx,
    wc.wc_name,
        CASE
            WHEN (uwc.wc_ndx IS NOT NULL) THEN true
            ELSE false
        END AS assoc_true
   FROM ((((((fetchit_landing_user_to_manage_last_submit f
     JOIN data.list_users u USING (user_ndx))
     JOIN data.assoc_user_to_loc ul USING (user_ndx))
     JOIN data.assoc_loc_to_water_colors lwc USING (loc_ndx))
     JOIN data.list_locations l USING (loc_ndx))
     JOIN data.list_water_colors wc ON ((wc.wc_ndx = lwc.wc_ndx)))
     LEFT JOIN data.assoc_user_to_water_color uwc ON (((uwc.wc_ndx = lwc.wc_ndx) AND (uwc.user_ndx = f.user_ndx))))
  GROUP BY f.user_ndx, u.user_name, lwc.wc_ndx, uwc.wc_ndx, wc.wc_name,
        CASE
            WHEN (uwc.wc_ndx IS NOT NULL) THEN true
            ELSE false
        END
  ORDER BY
        CASE
            WHEN (uwc.wc_ndx IS NOT NULL) THEN true
            ELSE false
        END DESC, wc.wc_name;


ALTER TABLE table_display_build_assoc_triple_users_locs_wcs_prep OWNER TO ark_admin;

--
-- TOC entry 281 (class 1259 OID 25701)
-- Name: table_display_build_assoc_triple_users_locs_wcs; Type: VIEW; Schema: tools; Owner: ark_admin
--

CREATE VIEW table_display_build_assoc_triple_users_locs_wcs AS
 SELECT t.user_name,
    t.loc_name,
    t.wc_ndx,
    t.wc_name
   FROM table_display_build_assoc_triple_users_locs_wcs_prep t
  ORDER BY t.assoc_true DESC, t.wc_name;


ALTER TABLE table_display_build_assoc_triple_users_locs_wcs OWNER TO ark_admin;

SET search_path = web, pg_catalog;

--
-- TOC entry 260 (class 1259 OID 25512)
-- Name: assoc_request_to_landing_tables_view; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW assoc_request_to_landing_tables_view AS
 SELECT a.req_type_ndx,
    a.primary_landing_table_ndx,
    l.landing_table_descrip AS primary_landing_table_descrip,
    a.secondary_landing_table_ndx,
    ll.landing_table_descrip AS secondary_landing_table_descrip,
    a.notes
   FROM ((data.assoc_request_to_landing_tables a
     JOIN data.list_request_landing_tables l ON ((l.landing_table_ndx = a.primary_landing_table_ndx)))
     LEFT JOIN data.list_request_landing_tables ll ON ((ll.landing_table_ndx = a.secondary_landing_table_ndx)));


ALTER TABLE assoc_request_to_landing_tables_view OWNER TO ark_admin;

--
-- TOC entry 227 (class 1259 OID 25093)
-- Name: exchange_from_locs_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW exchange_from_locs_dropdown AS
 SELECT l.loc_ndx,
    l.loc_name
   FROM data.list_locations l
  WHERE l.dd_exch_from;


ALTER TABLE exchange_from_locs_dropdown OWNER TO ark_admin;

--
-- TOC entry 237 (class 1259 OID 25167)
-- Name: exchange_from_loctype_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW exchange_from_loctype_dropdown AS
 SELECT t.deliv_loc_type_ndx,
    t.deliv_loc_type_descrip,
    t.display_order
   FROM data.list_delivery_loc_types t
  WHERE t.dd_exch_from
  ORDER BY t.display_order, t.deliv_loc_type_descrip;


ALTER TABLE exchange_from_loctype_dropdown OWNER TO ark_admin;

--
-- TOC entry 233 (class 1259 OID 25150)
-- Name: exchange_from_owners_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW exchange_from_owners_dropdown AS
 SELECT l.own_ndx,
    l.own_name
   FROM data.list_ownerentities l
  WHERE l.dd_transfer_from;


ALTER TABLE exchange_from_owners_dropdown OWNER TO ark_admin;

--
-- TOC entry 243 (class 1259 OID 25317)
-- Name: exchange_from_wc_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW exchange_from_wc_dropdown AS
 SELECT w.wc_ndx,
    w.wc_name
   FROM data.list_water_colors w
  WHERE w.dd_exch_from
  ORDER BY w.display_order, w.wc_name;


ALTER TABLE exchange_from_wc_dropdown OWNER TO ark_admin;

--
-- TOC entry 226 (class 1259 OID 25089)
-- Name: exchange_to_locs_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW exchange_to_locs_dropdown AS
 SELECT l.loc_ndx,
    l.loc_name
   FROM data.list_locations l
  WHERE l.dd_exch_to;


ALTER TABLE exchange_to_locs_dropdown OWNER TO ark_admin;

--
-- TOC entry 236 (class 1259 OID 25163)
-- Name: exchange_to_loctype_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW exchange_to_loctype_dropdown AS
 SELECT t.deliv_loc_type_ndx,
    t.deliv_loc_type_descrip,
    t.display_order
   FROM data.list_delivery_loc_types t
  WHERE t.dd_exch_to
  ORDER BY t.display_order, t.deliv_loc_type_descrip;


ALTER TABLE exchange_to_loctype_dropdown OWNER TO ark_admin;

--
-- TOC entry 232 (class 1259 OID 25146)
-- Name: exchange_to_owners_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW exchange_to_owners_dropdown AS
 SELECT l.own_ndx,
    l.own_name
   FROM data.list_ownerentities l
  WHERE l.dd_transfer_to;


ALTER TABLE exchange_to_owners_dropdown OWNER TO ark_admin;

--
-- TOC entry 244 (class 1259 OID 25321)
-- Name: exchange_to_wc_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW exchange_to_wc_dropdown AS
 SELECT w.wc_ndx,
    w.wc_name
   FROM data.list_water_colors w
  WHERE w.dd_exch_to
  ORDER BY w.display_order, w.wc_name;


ALTER TABLE exchange_to_wc_dropdown OWNER TO ark_admin;

--
-- TOC entry 230 (class 1259 OID 25116)
-- Name: landing_form1; Type: TABLE; Schema: web; Owner: ark_admin
--

CREATE TABLE landing_form1 (
    landing_ndx integer NOT NULL,
    user_ndx integer,
    own_ndx_selected integer,
    default_selection boolean,
    ownerentity_name text,
    ownerentity_email text,
    ownerentity_phone text,
    additional_info text,
    user_entity text,
    user_email text,
    user_phone text,
    submit_timestamp timestamp without time zone DEFAULT now() NOT NULL,
    drupal_userid integer,
    req_type_ndx integer
);


ALTER TABLE landing_form1 OWNER TO ark_admin;

--
-- TOC entry 2667 (class 0 OID 0)
-- Dependencies: 230
-- Name: TABLE landing_form1; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON TABLE landing_form1 IS 'Raw landing table for the contact info page used by all form types.  This table is emptied after the final submission of a form, and values are saved with the appropriate form type record values to the proper archive schema log table.';


--
-- TOC entry 2668 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN landing_form1.landing_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_form1.landing_ndx IS 'auto generating table index';


--
-- TOC entry 2669 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN landing_form1.user_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_form1.user_ndx IS 'index for system user submitting the form, keyed to [data].[list_users]';


--
-- TOC entry 2670 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN landing_form1.own_ndx_selected; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_form1.own_ndx_selected IS 'index for ownerentity user submitting on behalf of, keyed to [data].[list_ownerentities]';


--
-- TOC entry 2671 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN landing_form1.default_selection; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_form1.default_selection IS 'check-box for "make this my default selection" option; when true, update the appropriate user to entity assoc records.';


--
-- TOC entry 2672 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN landing_form1.ownerentity_name; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_form1.ownerentity_name IS 'name for the own_ndx_selected (user may have edited this)';


--
-- TOC entry 2673 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN landing_form1.ownerentity_email; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_form1.ownerentity_email IS 'email address for the own_ndx_selected (user may have edited this)';


--
-- TOC entry 2674 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN landing_form1.ownerentity_phone; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_form1.ownerentity_phone IS 'phone number field for the own_ndx_selected (user may have edited this)';


--
-- TOC entry 2675 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN landing_form1.additional_info; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_form1.additional_info IS 'additional info field (not required)';


--
-- TOC entry 2676 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN landing_form1.user_entity; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_form1.user_entity IS 'ownerentity name associated with the system user submitting the form (user may have changed this)';


--
-- TOC entry 2677 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN landing_form1.user_email; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_form1.user_email IS 'email address associated with the system user submitting the form (user may have changed this)';


--
-- TOC entry 2678 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN landing_form1.user_phone; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_form1.user_phone IS 'primary contact phone # associated with the system user submitting the form (user may have changed this)';


--
-- TOC entry 2679 (class 0 OID 0)
-- Dependencies: 230
-- Name: COLUMN landing_form1.drupal_userid; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_form1.drupal_userid IS 'drupal user submitting the form';


--
-- TOC entry 242 (class 1259 OID 25296)
-- Name: landing_form1_json; Type: TABLE; Schema: web; Owner: ark_admin
--

CREATE TABLE landing_form1_json (
    json_obj json,
    drupal_userid integer
);


ALTER TABLE landing_form1_json OWNER TO ark_admin;

--
-- TOC entry 229 (class 1259 OID 25114)
-- Name: landing_form1_landing_ndx_seq; Type: SEQUENCE; Schema: web; Owner: ark_admin
--

CREATE SEQUENCE landing_form1_landing_ndx_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE landing_form1_landing_ndx_seq OWNER TO ark_admin;

--
-- TOC entry 2682 (class 0 OID 0)
-- Dependencies: 229
-- Name: landing_form1_landing_ndx_seq; Type: SEQUENCE OWNED BY; Schema: web; Owner: ark_admin
--

ALTER SEQUENCE landing_form1_landing_ndx_seq OWNED BY landing_form1.landing_ndx;


--
-- TOC entry 276 (class 1259 OID 25643)
-- Name: landing_request_cancellation; Type: TABLE; Schema: web; Owner: ark_admin
--

CREATE TABLE landing_request_cancellation (
    landing_ndx bigint NOT NULL,
    submit_timestamp timestamp without time zone DEFAULT now() NOT NULL,
    drupal_userid integer
);


ALTER TABLE landing_request_cancellation OWNER TO ark_admin;

--
-- TOC entry 2684 (class 0 OID 0)
-- Dependencies: 276
-- Name: TABLE landing_request_cancellation; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON TABLE landing_request_cancellation IS 'Raw landing table for data submitted from the Request Cancellation form.';


--
-- TOC entry 2685 (class 0 OID 0)
-- Dependencies: 276
-- Name: COLUMN landing_request_cancellation.landing_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_cancellation.landing_ndx IS 'landing table index linking to associated Form 1 record';


--
-- TOC entry 2686 (class 0 OID 0)
-- Dependencies: 276
-- Name: COLUMN landing_request_cancellation.drupal_userid; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_cancellation.drupal_userid IS 'drupal user submitting the form';


--
-- TOC entry 239 (class 1259 OID 25210)
-- Name: landing_request_exchange; Type: TABLE; Schema: web; Owner: ark_admin
--

CREATE TABLE landing_request_exchange (
    landing_ndx bigint NOT NULL,
    exchange_start_date date,
    exchange_start_time time without time zone,
    exchange_end_date date,
    exchange_end_time time without time zone,
    duration_days text,
    exchange_rate text,
    unit_ndx integer,
    to_deliv_loc_type_ndx integer,
    to_loc_ndx integer,
    to_wc_ndx integer,
    to_own_ndx integer,
    from_deliv_loc_type_ndx integer,
    from_loc_ndx integer,
    from_wc_ndx integer,
    from_own_ndx integer,
    additional_notes text,
    submit_timestamp timestamp without time zone DEFAULT now() NOT NULL,
    drupal_userid integer
);


ALTER TABLE landing_request_exchange OWNER TO ark_admin;

--
-- TOC entry 2688 (class 0 OID 0)
-- Dependencies: 239
-- Name: TABLE landing_request_exchange; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON TABLE landing_request_exchange IS 'Raw landing table for data submitted from the Exchange Request form.  This table is emptied after each submission processing, but records are saved to archive.landing_request_reservoir_log';


--
-- TOC entry 2689 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.landing_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.landing_ndx IS 'landing table index linking to associated Form 1 record';


--
-- TOC entry 2690 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.exchange_start_date; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.exchange_start_date IS 'Specified start date';


--
-- TOC entry 2691 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.exchange_start_time; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.exchange_start_time IS 'requested start time';


--
-- TOC entry 2692 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.exchange_end_date; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.exchange_end_date IS 'Specified end date';


--
-- TOC entry 2693 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.exchange_end_time; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.exchange_end_time IS 'requested end time';


--
-- TOC entry 2694 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.duration_days; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.duration_days IS 'exchange duration in days';


--
-- TOC entry 2695 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.exchange_rate; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.exchange_rate IS 'Requested exchange rate';


--
-- TOC entry 2696 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.unit_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.unit_ndx IS 'Selected units for release amount (cfs or af/day) keyed to table [data].[list_units]';


--
-- TOC entry 2697 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.to_deliv_loc_type_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.to_deliv_loc_type_ndx IS 'Exchange to location type (decreed storage or diversion point)';


--
-- TOC entry 2698 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.to_loc_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.to_loc_ndx IS 'Exchange to location, keyed to table [data].[list_locations]';


--
-- TOC entry 2699 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.to_wc_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.to_wc_ndx IS 'Exchange to Water Color keyed to table [data].[list_water_colors]';


--
-- TOC entry 2700 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.to_own_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.to_own_ndx IS 'Owner of stored water (if deliv loc type is storage)';


--
-- TOC entry 2701 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.from_deliv_loc_type_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.from_deliv_loc_type_ndx IS 'Exchange to location type (decreed storage or diversion point)';


--
-- TOC entry 2702 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.from_loc_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.from_loc_ndx IS 'Exchange to location, keyed to table [data].[list_locations]';


--
-- TOC entry 2703 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.from_wc_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.from_wc_ndx IS 'Exchange to Water Color keyed to table [data].[list_water_colors]';


--
-- TOC entry 2704 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.from_own_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.from_own_ndx IS 'Owner of released water (if deliv loc type is release)';


--
-- TOC entry 2705 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.additional_notes; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.additional_notes IS 'Additional notes added by user';


--
-- TOC entry 2706 (class 0 OID 0)
-- Dependencies: 239
-- Name: COLUMN landing_request_exchange.drupal_userid; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_exchange.drupal_userid IS 'drupal user submitting the form';


--
-- TOC entry 256 (class 1259 OID 25455)
-- Name: landing_request_exchange_json; Type: TABLE; Schema: web; Owner: ark_admin
--

CREATE TABLE landing_request_exchange_json (
    json_obj json,
    drupal_userid integer
);


ALTER TABLE landing_request_exchange_json OWNER TO ark_admin;

--
-- TOC entry 273 (class 1259 OID 25620)
-- Name: landing_request_exchange_secondary; Type: TABLE; Schema: web; Owner: ark_admin
--

CREATE TABLE landing_request_exchange_secondary (
    landing_ndx bigint NOT NULL,
    from_loc_ndx integer,
    exchange_start_date date,
    exchange_rate text,
    drupal_userid integer
);


ALTER TABLE landing_request_exchange_secondary OWNER TO ark_admin;

--
-- TOC entry 275 (class 1259 OID 25637)
-- Name: landing_request_exchange_secondary_json; Type: TABLE; Schema: web; Owner: ark_admin
--

CREATE TABLE landing_request_exchange_secondary_json (
    json_obj json,
    drupal_userid integer
);


ALTER TABLE landing_request_exchange_secondary_json OWNER TO ark_admin;

--
-- TOC entry 231 (class 1259 OID 25124)
-- Name: landing_request_reservoir; Type: TABLE; Schema: web; Owner: ark_admin
--

CREATE TABLE landing_request_reservoir (
    landing_ndx bigint NOT NULL,
    loc_ndx integer,
    release_start_date date,
    release_start_time time without time zone,
    deliv_loc_type_ndx integer,
    release_amount text,
    unit_ndx integer,
    duration_days text,
    wc_ndx integer,
    additional_notes text,
    submit_timestamp timestamp without time zone DEFAULT now() NOT NULL,
    drupal_userid integer
);


ALTER TABLE landing_request_reservoir OWNER TO ark_admin;

--
-- TOC entry 2711 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE landing_request_reservoir; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON TABLE landing_request_reservoir IS 'Raw landing table for data submitted from the Reservoir Releases Request form.  This table is emptied after each submission processing, but records are saved to archive.landing_request_reservoir_log';


--
-- TOC entry 2712 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN landing_request_reservoir.landing_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir.landing_ndx IS 'landing table index linking to associated Form 1 record';


--
-- TOC entry 2713 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN landing_request_reservoir.loc_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir.loc_ndx IS 'Selected release from location, keyed to table [data].[list_locations]';


--
-- TOC entry 2714 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN landing_request_reservoir.release_start_date; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir.release_start_date IS 'Specified release start date';


--
-- TOC entry 2715 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN landing_request_reservoir.release_start_time; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir.release_start_time IS 'requested release time';


--
-- TOC entry 2716 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN landing_request_reservoir.deliv_loc_type_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir.deliv_loc_type_ndx IS 'Delivery Location Type selection (At the reservoir or at the headgate), keyed to table [data].[list_delivery_loc_types]';


--
-- TOC entry 2717 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN landing_request_reservoir.release_amount; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir.release_amount IS 'Requested release amount - this field should be numeric';


--
-- TOC entry 2718 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN landing_request_reservoir.unit_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir.unit_ndx IS 'Selected units for release amount (cfs or af/day) keyed to table [data].[list_units]';


--
-- TOC entry 2719 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN landing_request_reservoir.duration_days; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir.duration_days IS 'release duration requested in days (this field should be numeric)';


--
-- TOC entry 2720 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN landing_request_reservoir.wc_ndx; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir.wc_ndx IS 'Selected Water Color for release (aka type of reservoir water) keyed to table [data].[list_water_colors]';


--
-- TOC entry 2721 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN landing_request_reservoir.additional_notes; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir.additional_notes IS 'Additional notes added by user on the deliver request details page';


--
-- TOC entry 2722 (class 0 OID 0)
-- Dependencies: 231
-- Name: COLUMN landing_request_reservoir.drupal_userid; Type: COMMENT; Schema: web; Owner: ark_admin
--

COMMENT ON COLUMN landing_request_reservoir.drupal_userid IS 'drupal user submitting the form';


--
-- TOC entry 255 (class 1259 OID 25436)
-- Name: landing_request_reservoir_json; Type: TABLE; Schema: web; Owner: ark_admin
--

CREATE TABLE landing_request_reservoir_json (
    json_obj json,
    drupal_userid integer
);


ALTER TABLE landing_request_reservoir_json OWNER TO ark_admin;

--
-- TOC entry 240 (class 1259 OID 25222)
-- Name: list_users_and_owners_view; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW list_users_and_owners_view AS
 SELECT u.user_ndx,
    o.own_ndx AS user_own_ndx,
    u.user_name,
    p.own_name AS user_entity,
    u.user_email,
    u.user_phone_primary AS user_phone,
    p.own_ndx AS assoc_own_ndx,
    o.own_name AS assoc_entity,
    o.own_email AS assoc_entity_email,
    o.own_phone AS assoc_entity_phone,
    u.drupal_userid,
    a.default_user,
    a.form1_display
   FROM (((data.list_users u
     JOIN data.assoc_user_to_ownerentity a ON ((a.user_ndx = u.user_ndx)))
     JOIN data.list_ownerentities o ON ((o.own_ndx = a.own_ndx)))
     JOIN data.list_ownerentities p ON ((u.own_ndx = p.own_ndx)))
  ORDER BY u.user_ndx;


ALTER TABLE list_users_and_owners_view OWNER TO ark_admin;

--
-- TOC entry 248 (class 1259 OID 25388)
-- Name: list_users_view; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW list_users_view AS
 SELECT u.user_ndx,
    u.user_name,
    o.own_ndx,
    o.own_name,
    u.user_email,
    u.user_phone_primary,
    u.drupal_userid,
    a.default_user
   FROM ((data.list_users u
     JOIN data.assoc_user_to_ownerentity a ON ((a.user_ndx = u.user_ndx)))
     JOIN data.list_ownerentities o ON ((o.own_ndx = a.own_ndx)));


ALTER TABLE list_users_view OWNER TO ark_admin;

--
-- TOC entry 234 (class 1259 OID 25155)
-- Name: request_type_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW request_type_dropdown AS
 SELECT l.req_type_ndx,
    l.req_type_descrip,
    l.display_order
   FROM data.list_request_types l
  ORDER BY l.display_order, l.req_type_descrip;


ALTER TABLE request_type_dropdown OWNER TO ark_admin;

--
-- TOC entry 235 (class 1259 OID 25159)
-- Name: reservoir_release_loctype_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW reservoir_release_loctype_dropdown AS
 SELECT t.deliv_loc_type_ndx,
    t.deliv_loc_type_descrip,
    t.display_order
   FROM data.list_delivery_loc_types t
  WHERE t.dd_release
  ORDER BY t.display_order, t.deliv_loc_type_descrip;


ALTER TABLE reservoir_release_loctype_dropdown OWNER TO ark_admin;

--
-- TOC entry 225 (class 1259 OID 25071)
-- Name: reservoir_release_res_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW reservoir_release_res_dropdown AS
 SELECT l.loc_ndx,
    l.loc_name
   FROM data.list_locations l
  WHERE l.dd_release
  ORDER BY l.display_order, l.loc_name;


ALTER TABLE reservoir_release_res_dropdown OWNER TO ark_admin;

--
-- TOC entry 224 (class 1259 OID 25059)
-- Name: reservoir_release_wc_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW reservoir_release_wc_dropdown AS
 SELECT w.wc_ndx,
    w.wc_name,
    a.loc_ndx
   FROM (data.list_water_colors w
     JOIN data.assoc_loc_to_water_colors a USING (wc_ndx))
  WHERE w.dd_release
  ORDER BY w.display_order, w.wc_name;


ALTER TABLE reservoir_release_wc_dropdown OWNER TO ark_admin;

--
-- TOC entry 238 (class 1259 OID 25171)
-- Name: units_dropdown; Type: VIEW; Schema: web; Owner: ark_admin
--

CREATE VIEW units_dropdown AS
 SELECT l.unit_ndx,
    l.unit_abbrev,
    l.unit_ndx AS display_order
   FROM data.list_units l
  ORDER BY l.unit_ndx;


ALTER TABLE units_dropdown OWNER TO ark_admin;

SET search_path = data, pg_catalog;

--
-- TOC entry 2292 (class 2604 OID 16687)
-- Name: dc_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_diversion_classes ALTER COLUMN dc_ndx SET DEFAULT nextval('assoc_diversion_classes_dc_ndx_seq'::regclass);


--
-- TOC entry 2287 (class 2604 OID 16604)
-- Name: exch_fr_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_from ALTER COLUMN exch_fr_ndx SET DEFAULT nextval('data_assoc_exch_from_exch_fr_ndx_seq'::regclass);


--
-- TOC entry 2286 (class 2604 OID 16596)
-- Name: exch_to_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_to ALTER COLUMN exch_to_ndx SET DEFAULT nextval('data_assoc_exch_to_exch_to_ndx_seq'::regclass);


--
-- TOC entry 2289 (class 2604 OID 16634)
-- Name: tran_to_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_transfers_to ALTER COLUMN tran_to_ndx SET DEFAULT nextval('data_assoc_transfers_to_tran_to_ndx_seq'::regclass);


--
-- TOC entry 2288 (class 2604 OID 16610)
-- Name: req_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_requests ALTER COLUMN req_ndx SET DEFAULT nextval('data_requests_req_ndx_seq'::regclass);


--
-- TOC entry 2285 (class 2604 OID 16576)
-- Name: log_req_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_requests_log ALTER COLUMN log_req_ndx SET DEFAULT nextval('data_requests_log_log_req_ndx_seq'::regclass);


--
-- TOC entry 2291 (class 2604 OID 16676)
-- Name: cancel_by_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_cancelled_by ALTER COLUMN cancel_by_ndx SET DEFAULT nextval('list_cancelled_by_cancel_by_ndx_seq'::regclass);


--
-- TOC entry 2290 (class 2604 OID 16665)
-- Name: cancel_reason_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_cancelled_reasons ALTER COLUMN cancel_reason_ndx SET DEFAULT nextval('list_cancelled_reasons_cancel_reason_ndx_seq'::regclass);


--
-- TOC entry 2282 (class 2604 OID 16498)
-- Name: deliv_loc_type_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_delivery_loc_types ALTER COLUMN deliv_loc_type_ndx SET DEFAULT nextval('list_delivery_loc_types_deliv_loc_type_ndx_seq'::regclass);


--
-- TOC entry 2276 (class 2604 OID 16423)
-- Name: loc_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_locations ALTER COLUMN loc_ndx SET DEFAULT nextval('list_locations_loc_ndx_seq'::regclass);


--
-- TOC entry 2281 (class 2604 OID 16489)
-- Name: log_event_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_log_events ALTER COLUMN log_event_ndx SET DEFAULT nextval('list_log_events_log_event_ndx_seq'::regclass);


--
-- TOC entry 2277 (class 2604 OID 16441)
-- Name: own_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_ownerentities ALTER COLUMN own_ndx SET DEFAULT nextval('list_ownerentities_own_ndx_seq'::regclass);


--
-- TOC entry 2299 (class 2604 OID 25479)
-- Name: landing_table_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_request_landing_tables ALTER COLUMN landing_table_ndx SET DEFAULT nextval('list_request_landing_tables_landing_table_ndx_seq'::regclass);


--
-- TOC entry 2279 (class 2604 OID 16468)
-- Name: req_status_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_request_status ALTER COLUMN req_status_ndx SET DEFAULT nextval('list_request_status_req_status_ndx_seq'::regclass);


--
-- TOC entry 2283 (class 2604 OID 16507)
-- Name: req_type_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_request_types ALTER COLUMN req_type_ndx SET DEFAULT nextval('list_requests_types_req_type_ndx_seq'::regclass);


--
-- TOC entry 2284 (class 2604 OID 16518)
-- Name: unit_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_units ALTER COLUMN unit_ndx SET DEFAULT nextval('list_units_unit_ndx_seq'::regclass);


--
-- TOC entry 2275 (class 2604 OID 16414)
-- Name: user_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_users ALTER COLUMN user_ndx SET DEFAULT nextval('list_user_user_ndx_seq'::regclass);


--
-- TOC entry 2280 (class 2604 OID 16477)
-- Name: wc_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_water_colors ALTER COLUMN wc_ndx SET DEFAULT nextval('list_water_colors_wc_ndx_seq'::regclass);


--
-- TOC entry 2278 (class 2604 OID 16450)
-- Name: calc_type_ndx; Type: DEFAULT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_wc_calc_types ALTER COLUMN calc_type_ndx SET DEFAULT nextval('list_wc_calc_types_calc_type_ndx_seq'::regclass);


SET search_path = web, pg_catalog;

--
-- TOC entry 2294 (class 2604 OID 25119)
-- Name: landing_ndx; Type: DEFAULT; Schema: web; Owner: ark_admin
--

ALTER TABLE ONLY landing_form1 ALTER COLUMN landing_ndx SET DEFAULT nextval('landing_form1_landing_ndx_seq'::regclass);


SET search_path = data, pg_catalog;

--
-- TOC entry 2324 (class 2606 OID 16767)
-- Name: assoc_loc_to_water_colors_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_loc_to_water_colors
    ADD CONSTRAINT assoc_loc_to_water_colors_pkey PRIMARY KEY (loc_ndx, wc_ndx);


--
-- TOC entry 2370 (class 2606 OID 25492)
-- Name: assoc_request_to_landing_tables_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_request_to_landing_tables
    ADD CONSTRAINT assoc_request_to_landing_tables_pkey PRIMARY KEY (req_type_ndx, primary_landing_table_ndx);


--
-- TOC entry 2322 (class 2606 OID 16753)
-- Name: assoc_user_to_loc_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_user_to_loc
    ADD CONSTRAINT assoc_user_to_loc_pkey PRIMARY KEY (user_ndx, loc_ndx);


--
-- TOC entry 2358 (class 2606 OID 17125)
-- Name: assoc_user_to_ownerentity_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_user_to_ownerentity
    ADD CONSTRAINT assoc_user_to_ownerentity_pkey PRIMARY KEY (user_ndx, own_ndx);


--
-- TOC entry 2326 (class 2606 OID 16741)
-- Name: assoc_user_to_water_color_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_user_to_water_color
    ADD CONSTRAINT assoc_user_to_water_color_pkey PRIMARY KEY (user_ndx, wc_ndx);


--
-- TOC entry 2308 (class 2606 OID 16658)
-- Name: calc_type_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_wc_calc_types
    ADD CONSTRAINT calc_type_ndx_pk PRIMARY KEY (calc_type_ndx);


--
-- TOC entry 2354 (class 2606 OID 16681)
-- Name: cancel_by_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_cancelled_by
    ADD CONSTRAINT cancel_by_ndx_pk PRIMARY KEY (cancel_by_ndx);


--
-- TOC entry 2342 (class 2606 OID 16718)
-- Name: cancel_datetime_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_cancellations
    ADD CONSTRAINT cancel_datetime_pk PRIMARY KEY (cancel_datetime);


--
-- TOC entry 2352 (class 2606 OID 16670)
-- Name: cancel_reason_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_cancelled_reasons
    ADD CONSTRAINT cancel_reason_ndx_pk PRIMARY KEY (cancel_reason_ndx);


--
-- TOC entry 2332 (class 2606 OID 16953)
-- Name: data_exchanges_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_exchanges
    ADD CONSTRAINT data_exchanges_pkey PRIMARY KEY (req_ndx);


--
-- TOC entry 2340 (class 2606 OID 16936)
-- Name: data_rel_modified_log_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_rel_modified_log
    ADD CONSTRAINT data_rel_modified_log_pkey PRIMARY KEY (req_ndx);


--
-- TOC entry 2372 (class 2606 OID 25668)
-- Name: data_requests_form1_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_requests_form1_content
    ADD CONSTRAINT data_requests_form1_pkey PRIMARY KEY (req_ndx);


--
-- TOC entry 2338 (class 2606 OID 16779)
-- Name: data_requests_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_requests
    ADD CONSTRAINT data_requests_pkey PRIMARY KEY (req_ndx);


--
-- TOC entry 2344 (class 2606 OID 17070)
-- Name: data_transfers_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_transfers
    ADD CONSTRAINT data_transfers_pkey PRIMARY KEY (req_ndx);


--
-- TOC entry 2348 (class 2606 OID 17092)
-- Name: data_uscapture_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_uscapture
    ADD CONSTRAINT data_uscapture_pkey PRIMARY KEY (req_ndx);


--
-- TOC entry 2356 (class 2606 OID 16692)
-- Name: dc_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_diversion_classes
    ADD CONSTRAINT dc_ndx_pk PRIMARY KEY (dc_ndx);


--
-- TOC entry 2316 (class 2606 OID 16704)
-- Name: deliv_loc_type_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_delivery_loc_types
    ADD CONSTRAINT deliv_loc_type_ndx_pk PRIMARY KEY (deliv_loc_type_ndx);


--
-- TOC entry 2336 (class 2606 OID 16714)
-- Name: exch_fr_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_from
    ADD CONSTRAINT exch_fr_ndx_pk PRIMARY KEY (exch_fr_ndx);


--
-- TOC entry 2334 (class 2606 OID 16712)
-- Name: exch_to_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_to
    ADD CONSTRAINT exch_to_ndx_pk PRIMARY KEY (exch_to_ndx);


--
-- TOC entry 2350 (class 2606 OID 16650)
-- Name: list_drupal_user_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_drupal_users
    ADD CONSTRAINT list_drupal_user_pkey PRIMARY KEY (drupal_userid);


--
-- TOC entry 2368 (class 2606 OID 25484)
-- Name: list_request_landing_tables_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_request_landing_tables
    ADD CONSTRAINT list_request_landing_tables_pkey PRIMARY KEY (landing_table_ndx);


--
-- TOC entry 2304 (class 2606 OID 16654)
-- Name: loc_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_locations
    ADD CONSTRAINT loc_ndx_pk PRIMARY KEY (loc_ndx);


--
-- TOC entry 2314 (class 2606 OID 16700)
-- Name: log_event_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_log_events
    ADD CONSTRAINT log_event_ndx_pk PRIMARY KEY (log_event_ndx);


--
-- TOC entry 2328 (class 2606 OID 16708)
-- Name: log_req_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_requests_log
    ADD CONSTRAINT log_req_ndx_pk PRIMARY KEY (log_req_ndx);


--
-- TOC entry 2306 (class 2606 OID 16656)
-- Name: own_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_ownerentities
    ADD CONSTRAINT own_ndx_pk PRIMARY KEY (own_ndx);


--
-- TOC entry 2330 (class 2606 OID 16710)
-- Name: req_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_releases
    ADD CONSTRAINT req_ndx_pk PRIMARY KEY (req_ndx);


--
-- TOC entry 2310 (class 2606 OID 16694)
-- Name: req_status_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_request_status
    ADD CONSTRAINT req_status_ndx_pk PRIMARY KEY (req_status_ndx);


--
-- TOC entry 2318 (class 2606 OID 16696)
-- Name: req_type_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_request_types
    ADD CONSTRAINT req_type_ndx_pk PRIMARY KEY (req_type_ndx);


--
-- TOC entry 2360 (class 2606 OID 25046)
-- Name: test_list_users_pkey; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY test_list_users
    ADD CONSTRAINT test_list_users_pkey PRIMARY KEY (username);


--
-- TOC entry 2346 (class 2606 OID 16716)
-- Name: tran_to_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_transfers_to
    ADD CONSTRAINT tran_to_ndx_pk PRIMARY KEY (tran_to_ndx);


--
-- TOC entry 2320 (class 2606 OID 16702)
-- Name: unit_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_units
    ADD CONSTRAINT unit_ndx_pk PRIMARY KEY (unit_ndx);


--
-- TOC entry 2302 (class 2606 OID 16706)
-- Name: user_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_users
    ADD CONSTRAINT user_ndx_pk PRIMARY KEY (user_ndx);


--
-- TOC entry 2312 (class 2606 OID 16698)
-- Name: wc_ndx_pk; Type: CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_water_colors
    ADD CONSTRAINT wc_ndx_pk PRIMARY KEY (wc_ndx);


SET search_path = tools, pg_catalog;

--
-- TOC entry 2366 (class 2606 OID 25404)
-- Name: fetchit_landing_selected_user_none_pkey; Type: CONSTRAINT; Schema: tools; Owner: ark_admin
--

ALTER TABLE ONLY fetchit_landing_selected_user_selectnone
    ADD CONSTRAINT fetchit_landing_selected_user_none_pkey PRIMARY KEY (drupal_userid);


--
-- TOC entry 2362 (class 2606 OID 25348)
-- Name: fetchit_landing_selected_user_omniscient_pkey; Type: CONSTRAINT; Schema: tools; Owner: ark_admin
--

ALTER TABLE ONLY fetchit_landing_selected_user_selectall
    ADD CONSTRAINT fetchit_landing_selected_user_omniscient_pkey PRIMARY KEY (drupal_userid);


--
-- TOC entry 2364 (class 2606 OID 25365)
-- Name: fetchit_landing_selected_user_to_manage_pkey; Type: CONSTRAINT; Schema: tools; Owner: ark_admin
--

ALTER TABLE ONLY fetchit_landing_selected_user_to_manage
    ADD CONSTRAINT fetchit_landing_selected_user_to_manage_pkey PRIMARY KEY (user_ndx, drupal_userid);


SET search_path = data, pg_catalog;

--
-- TOC entry 2425 (class 2606 OID 17049)
-- Name: assoc_diversion_classes_calc_type_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_diversion_classes
    ADD CONSTRAINT assoc_diversion_classes_calc_type_ndx_fkey FOREIGN KEY (calc_type_ndx) REFERENCES list_wc_calc_types(calc_type_ndx);


--
-- TOC entry 2422 (class 2606 OID 17034)
-- Name: assoc_diversion_classes_loc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_diversion_classes
    ADD CONSTRAINT assoc_diversion_classes_loc_ndx_fkey FOREIGN KEY (loc_ndx) REFERENCES list_locations(loc_ndx);


--
-- TOC entry 2424 (class 2606 OID 17044)
-- Name: assoc_diversion_classes_own_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_diversion_classes
    ADD CONSTRAINT assoc_diversion_classes_own_ndx_fkey FOREIGN KEY (own_ndx) REFERENCES list_ownerentities(own_ndx);


--
-- TOC entry 2423 (class 2606 OID 17039)
-- Name: assoc_diversion_classes_wc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_diversion_classes
    ADD CONSTRAINT assoc_diversion_classes_wc_ndx_fkey FOREIGN KEY (wc_ndx) REFERENCES list_water_colors(wc_ndx);


--
-- TOC entry 2377 (class 2606 OID 16768)
-- Name: assoc_loc_to_water_colors_loc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_loc_to_water_colors
    ADD CONSTRAINT assoc_loc_to_water_colors_loc_ndx_fkey FOREIGN KEY (loc_ndx) REFERENCES list_locations(loc_ndx);


--
-- TOC entry 2378 (class 2606 OID 16773)
-- Name: assoc_loc_to_water_colors_wc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_loc_to_water_colors
    ADD CONSTRAINT assoc_loc_to_water_colors_wc_ndx_fkey FOREIGN KEY (wc_ndx) REFERENCES list_water_colors(wc_ndx);


--
-- TOC entry 2430 (class 2606 OID 25503)
-- Name: assoc_request_to_landing_table_secondary_landing_table_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_request_to_landing_tables
    ADD CONSTRAINT assoc_request_to_landing_table_secondary_landing_table_ndx_fkey FOREIGN KEY (secondary_landing_table_ndx) REFERENCES list_request_landing_tables(landing_table_ndx);


--
-- TOC entry 2429 (class 2606 OID 25498)
-- Name: assoc_request_to_landing_tables_landing_table_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_request_to_landing_tables
    ADD CONSTRAINT assoc_request_to_landing_tables_landing_table_ndx_fkey FOREIGN KEY (primary_landing_table_ndx) REFERENCES list_request_landing_tables(landing_table_ndx);


--
-- TOC entry 2428 (class 2606 OID 25493)
-- Name: assoc_request_to_landing_tables_req_type_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_request_to_landing_tables
    ADD CONSTRAINT assoc_request_to_landing_tables_req_type_ndx_fkey FOREIGN KEY (req_type_ndx) REFERENCES list_request_types(req_type_ndx);


--
-- TOC entry 2427 (class 2606 OID 17131)
-- Name: assoc_user_to_ownerentity_own_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_user_to_ownerentity
    ADD CONSTRAINT assoc_user_to_ownerentity_own_ndx_fkey FOREIGN KEY (own_ndx) REFERENCES list_ownerentities(own_ndx);


--
-- TOC entry 2426 (class 2606 OID 17126)
-- Name: assoc_user_to_ownerentity_user_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_user_to_ownerentity
    ADD CONSTRAINT assoc_user_to_ownerentity_user_ndx_fkey FOREIGN KEY (user_ndx) REFERENCES list_users(user_ndx);


--
-- TOC entry 2379 (class 2606 OID 16742)
-- Name: assoc_user_to_water_color_user_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_user_to_water_color
    ADD CONSTRAINT assoc_user_to_water_color_user_ndx_fkey FOREIGN KEY (user_ndx) REFERENCES list_users(user_ndx);


--
-- TOC entry 2380 (class 2606 OID 16747)
-- Name: assoc_user_to_water_color_wc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_user_to_water_color
    ADD CONSTRAINT assoc_user_to_water_color_wc_ndx_fkey FOREIGN KEY (wc_ndx) REFERENCES list_water_colors(wc_ndx);


--
-- TOC entry 2397 (class 2606 OID 16974)
-- Name: data_assoc_exch_from_fr_deliv_loc_type_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_from
    ADD CONSTRAINT data_assoc_exch_from_fr_deliv_loc_type_ndx_fkey FOREIGN KEY (fr_deliv_loc_type_ndx) REFERENCES list_delivery_loc_types(deliv_loc_type_ndx);


--
-- TOC entry 2396 (class 2606 OID 16969)
-- Name: data_assoc_exch_from_fr_loc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_from
    ADD CONSTRAINT data_assoc_exch_from_fr_loc_ndx_fkey FOREIGN KEY (fr_loc_ndx) REFERENCES list_locations(loc_ndx);


--
-- TOC entry 2399 (class 2606 OID 16984)
-- Name: data_assoc_exch_from_fr_own_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_from
    ADD CONSTRAINT data_assoc_exch_from_fr_own_ndx_fkey FOREIGN KEY (fr_own_ndx) REFERENCES list_ownerentities(own_ndx);


--
-- TOC entry 2398 (class 2606 OID 16979)
-- Name: data_assoc_exch_from_fr_water_color_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_from
    ADD CONSTRAINT data_assoc_exch_from_fr_water_color_ndx_fkey FOREIGN KEY (fr_water_color_ndx) REFERENCES list_water_colors(wc_ndx);


--
-- TOC entry 2395 (class 2606 OID 16964)
-- Name: data_assoc_exch_from_req_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_from
    ADD CONSTRAINT data_assoc_exch_from_req_ndx_fkey FOREIGN KEY (req_ndx) REFERENCES data_requests(req_ndx);


--
-- TOC entry 2390 (class 2606 OID 17009)
-- Name: data_assoc_exch_to_req_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_to
    ADD CONSTRAINT data_assoc_exch_to_req_ndx_fkey FOREIGN KEY (req_ndx) REFERENCES data_requests(req_ndx);


--
-- TOC entry 2392 (class 2606 OID 17019)
-- Name: data_assoc_exch_to_to_deliv_loc_type_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_to
    ADD CONSTRAINT data_assoc_exch_to_to_deliv_loc_type_ndx_fkey FOREIGN KEY (to_deliv_loc_type_ndx) REFERENCES list_delivery_loc_types(deliv_loc_type_ndx);


--
-- TOC entry 2391 (class 2606 OID 17014)
-- Name: data_assoc_exch_to_to_loc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_to
    ADD CONSTRAINT data_assoc_exch_to_to_loc_ndx_fkey FOREIGN KEY (to_loc_ndx) REFERENCES list_locations(loc_ndx);


--
-- TOC entry 2394 (class 2606 OID 17029)
-- Name: data_assoc_exch_to_to_own_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_to
    ADD CONSTRAINT data_assoc_exch_to_to_own_ndx_fkey FOREIGN KEY (to_own_ndx) REFERENCES list_ownerentities(own_ndx);


--
-- TOC entry 2393 (class 2606 OID 17024)
-- Name: data_assoc_exch_to_to_water_color_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_exch_to
    ADD CONSTRAINT data_assoc_exch_to_to_water_color_ndx_fkey FOREIGN KEY (to_water_color_ndx) REFERENCES list_water_colors(wc_ndx);


--
-- TOC entry 2413 (class 2606 OID 17071)
-- Name: data_assoc_transfers_to_req_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_transfers_to
    ADD CONSTRAINT data_assoc_transfers_to_req_ndx_fkey FOREIGN KEY (req_ndx) REFERENCES data_requests(req_ndx);


--
-- TOC entry 2414 (class 2606 OID 17076)
-- Name: data_assoc_transfers_to_to_own_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_transfers_to
    ADD CONSTRAINT data_assoc_transfers_to_to_own_ndx_fkey FOREIGN KEY (to_own_ndx) REFERENCES list_ownerentities(own_ndx);


--
-- TOC entry 2415 (class 2606 OID 17081)
-- Name: data_assoc_transfers_to_to_wc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_transfers_to
    ADD CONSTRAINT data_assoc_transfers_to_to_wc_ndx_fkey FOREIGN KEY (to_wc_ndx) REFERENCES list_water_colors(wc_ndx);


--
-- TOC entry 2416 (class 2606 OID 17086)
-- Name: data_assoc_transfers_to_units_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_assoc_transfers_to
    ADD CONSTRAINT data_assoc_transfers_to_units_ndx_fkey FOREIGN KEY (units_ndx) REFERENCES list_units(unit_ndx);


--
-- TOC entry 2408 (class 2606 OID 16900)
-- Name: data_cancellations_cancel_by_nxd_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_cancellations
    ADD CONSTRAINT data_cancellations_cancel_by_nxd_fkey FOREIGN KEY (cancel_by_nxd) REFERENCES list_cancelled_by(cancel_by_ndx);


--
-- TOC entry 2407 (class 2606 OID 16895)
-- Name: data_cancellations_req_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_cancellations
    ADD CONSTRAINT data_cancellations_req_ndx_fkey FOREIGN KEY (req_ndx) REFERENCES data_requests(req_ndx);


--
-- TOC entry 2409 (class 2606 OID 16905)
-- Name: data_cancellations_user_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_cancellations
    ADD CONSTRAINT data_cancellations_user_ndx_fkey FOREIGN KEY (user_ndx) REFERENCES list_users(user_ndx);


--
-- TOC entry 2388 (class 2606 OID 16954)
-- Name: data_exchanges_req_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_exchanges
    ADD CONSTRAINT data_exchanges_req_ndx_fkey FOREIGN KEY (req_ndx) REFERENCES data_requests(req_ndx);


--
-- TOC entry 2389 (class 2606 OID 16959)
-- Name: data_exchanges_units_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_exchanges
    ADD CONSTRAINT data_exchanges_units_ndx_fkey FOREIGN KEY (units_ndx) REFERENCES list_units(unit_ndx);


--
-- TOC entry 2406 (class 2606 OID 16947)
-- Name: data_rel_modified_log_deliv_loc_type_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_rel_modified_log
    ADD CONSTRAINT data_rel_modified_log_deliv_loc_type_ndx_fkey FOREIGN KEY (deliv_loc_type_ndx) REFERENCES list_delivery_loc_types(deliv_loc_type_ndx);


--
-- TOC entry 2405 (class 2606 OID 16942)
-- Name: data_rel_modified_log_log_req_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_rel_modified_log
    ADD CONSTRAINT data_rel_modified_log_log_req_ndx_fkey FOREIGN KEY (log_req_ndx) REFERENCES data_requests_log(log_req_ndx);


--
-- TOC entry 2404 (class 2606 OID 16937)
-- Name: data_rel_modified_log_req_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_rel_modified_log
    ADD CONSTRAINT data_rel_modified_log_req_ndx_fkey FOREIGN KEY (req_ndx) REFERENCES data_requests(req_ndx);


--
-- TOC entry 2385 (class 2606 OID 16920)
-- Name: data_releases_deliv_loc_type_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_releases
    ADD CONSTRAINT data_releases_deliv_loc_type_ndx_fkey FOREIGN KEY (deliv_loc_type_ndx) REFERENCES list_delivery_loc_types(deliv_loc_type_ndx);


--
-- TOC entry 2384 (class 2606 OID 16915)
-- Name: data_releases_fr_loc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_releases
    ADD CONSTRAINT data_releases_fr_loc_ndx_fkey FOREIGN KEY (fr_loc_ndx) REFERENCES list_locations(loc_ndx);


--
-- TOC entry 2386 (class 2606 OID 16925)
-- Name: data_releases_fr_wc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_releases
    ADD CONSTRAINT data_releases_fr_wc_ndx_fkey FOREIGN KEY (fr_wc_ndx) REFERENCES list_water_colors(wc_ndx);


--
-- TOC entry 2383 (class 2606 OID 16910)
-- Name: data_releases_req_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_releases
    ADD CONSTRAINT data_releases_req_ndx_fkey FOREIGN KEY (req_ndx) REFERENCES data_requests(req_ndx);


--
-- TOC entry 2387 (class 2606 OID 16930)
-- Name: data_releases_units_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_releases
    ADD CONSTRAINT data_releases_units_ndx_fkey FOREIGN KEY (units_ndx) REFERENCES list_units(unit_ndx);


--
-- TOC entry 2382 (class 2606 OID 16880)
-- Name: data_requests_log_log_event_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_requests_log
    ADD CONSTRAINT data_requests_log_log_event_ndx_fkey FOREIGN KEY (log_event_ndx) REFERENCES list_log_events(log_event_ndx);


--
-- TOC entry 2381 (class 2606 OID 16875)
-- Name: data_requests_log_req_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_requests_log
    ADD CONSTRAINT data_requests_log_req_ndx_fkey FOREIGN KEY (req_ndx) REFERENCES data_requests(req_ndx);


--
-- TOC entry 2403 (class 2606 OID 16870)
-- Name: data_requests_own_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_requests
    ADD CONSTRAINT data_requests_own_ndx_fkey FOREIGN KEY (own_ndx) REFERENCES list_ownerentities(own_ndx);


--
-- TOC entry 2401 (class 2606 OID 16860)
-- Name: data_requests_req_status_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_requests
    ADD CONSTRAINT data_requests_req_status_ndx_fkey FOREIGN KEY (req_status_ndx) REFERENCES list_request_status(req_status_ndx);


--
-- TOC entry 2400 (class 2606 OID 16855)
-- Name: data_requests_req_type_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_requests
    ADD CONSTRAINT data_requests_req_type_ndx_fkey FOREIGN KEY (req_type_ndx) REFERENCES list_request_types(req_type_ndx);


--
-- TOC entry 2402 (class 2606 OID 16865)
-- Name: data_requests_user_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_requests
    ADD CONSTRAINT data_requests_user_ndx_fkey FOREIGN KEY (user_ndx) REFERENCES list_users(user_ndx);


--
-- TOC entry 2410 (class 2606 OID 17054)
-- Name: data_transfers_fr_own_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_transfers
    ADD CONSTRAINT data_transfers_fr_own_ndx_fkey FOREIGN KEY (fr_own_ndx) REFERENCES list_ownerentities(own_ndx);


--
-- TOC entry 2412 (class 2606 OID 17064)
-- Name: data_transfers_fr_wc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_transfers
    ADD CONSTRAINT data_transfers_fr_wc_ndx_fkey FOREIGN KEY (fr_wc_ndx) REFERENCES list_water_colors(wc_ndx);


--
-- TOC entry 2411 (class 2606 OID 17059)
-- Name: data_transfers_req_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_transfers
    ADD CONSTRAINT data_transfers_req_ndx_fkey FOREIGN KEY (req_ndx) REFERENCES data_requests(req_ndx);


--
-- TOC entry 2420 (class 2606 OID 17108)
-- Name: data_uscapture_cap_by_own_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_uscapture
    ADD CONSTRAINT data_uscapture_cap_by_own_ndx_fkey FOREIGN KEY (cap_by_own_ndx) REFERENCES list_ownerentities(own_ndx);


--
-- TOC entry 2417 (class 2606 OID 17093)
-- Name: data_uscapture_fr_loc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_uscapture
    ADD CONSTRAINT data_uscapture_fr_loc_ndx_fkey FOREIGN KEY (fr_loc_ndx) REFERENCES list_locations(loc_ndx);


--
-- TOC entry 2418 (class 2606 OID 17098)
-- Name: data_uscapture_to_loc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_uscapture
    ADD CONSTRAINT data_uscapture_to_loc_ndx_fkey FOREIGN KEY (to_loc_ndx) REFERENCES list_locations(loc_ndx);


--
-- TOC entry 2421 (class 2606 OID 17113)
-- Name: data_uscapture_units_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_uscapture
    ADD CONSTRAINT data_uscapture_units_ndx_fkey FOREIGN KEY (units_ndx) REFERENCES list_units(unit_ndx);


--
-- TOC entry 2419 (class 2606 OID 17103)
-- Name: data_uscapture_wc_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY data_uscapture
    ADD CONSTRAINT data_uscapture_wc_ndx_fkey FOREIGN KEY (wc_ndx) REFERENCES list_water_colors(wc_ndx);


--
-- TOC entry 2373 (class 2606 OID 16850)
-- Name: list_users_drupal_userid_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_users
    ADD CONSTRAINT list_users_drupal_userid_fkey FOREIGN KEY (drupal_userid) REFERENCES list_drupal_users(drupal_userid);


--
-- TOC entry 2374 (class 2606 OID 25141)
-- Name: list_users_own_ndx_fkey; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY list_users
    ADD CONSTRAINT list_users_own_ndx_fkey FOREIGN KEY (own_ndx) REFERENCES list_ownerentities(own_ndx);


--
-- TOC entry 2375 (class 2606 OID 16728)
-- Name: loc_ndx_fk; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_user_to_loc
    ADD CONSTRAINT loc_ndx_fk FOREIGN KEY (loc_ndx) REFERENCES list_locations(loc_ndx);


--
-- TOC entry 2376 (class 2606 OID 16733)
-- Name: user_ndx_fk; Type: FK CONSTRAINT; Schema: data; Owner: ark_admin
--

ALTER TABLE ONLY assoc_user_to_loc
    ADD CONSTRAINT user_ndx_fk FOREIGN KEY (user_ndx) REFERENCES list_users(user_ndx);


SET search_path = web, pg_catalog;

--
-- TOC entry 2431 (class 2606 OID 25628)
-- Name: landing_request_exchange_secondary_from_loc_ndx_fkey; Type: FK CONSTRAINT; Schema: web; Owner: ark_admin
--

ALTER TABLE ONLY landing_request_exchange_secondary
    ADD CONSTRAINT landing_request_exchange_secondary_from_loc_ndx_fkey FOREIGN KEY (from_loc_ndx) REFERENCES data.list_locations(loc_ndx);


--
-- TOC entry 2572 (class 0 OID 0)
-- Dependencies: 9
-- Name: data; Type: ACL; Schema: -; Owner: ark_admin
--

REVOKE ALL ON SCHEMA data FROM PUBLIC;
REVOKE ALL ON SCHEMA data FROM ark_admin;
GRANT ALL ON SCHEMA data TO ark_admin;
GRANT USAGE ON SCHEMA data TO web_users;


--
-- TOC entry 2574 (class 0 OID 0)
-- Dependencies: 6
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- TOC entry 2575 (class 0 OID 0)
-- Dependencies: 12
-- Name: tools; Type: ACL; Schema: -; Owner: ark_admin
--

REVOKE ALL ON SCHEMA tools FROM PUBLIC;
REVOKE ALL ON SCHEMA tools FROM ark_admin;
GRANT ALL ON SCHEMA tools TO ark_admin;
GRANT USAGE ON SCHEMA tools TO web_users;


--
-- TOC entry 2576 (class 0 OID 0)
-- Dependencies: 10
-- Name: web; Type: ACL; Schema: -; Owner: ark_admin
--

REVOKE ALL ON SCHEMA web FROM PUBLIC;
REVOKE ALL ON SCHEMA web FROM ark_admin;
GRANT ALL ON SCHEMA web TO ark_admin;
GRANT USAGE ON SCHEMA web TO web_users;


SET search_path = data, pg_catalog;

--
-- TOC entry 2601 (class 0 OID 0)
-- Dependencies: 197
-- Name: assoc_loc_to_water_colors; Type: ACL; Schema: data; Owner: ark_admin
--

REVOKE ALL ON TABLE assoc_loc_to_water_colors FROM PUBLIC;
REVOKE ALL ON TABLE assoc_loc_to_water_colors FROM ark_admin;
GRANT ALL ON TABLE assoc_loc_to_water_colors TO ark_admin;
GRANT SELECT,INSERT,DELETE ON TABLE assoc_loc_to_water_colors TO web_users;


--
-- TOC entry 2602 (class 0 OID 0)
-- Dependencies: 259
-- Name: assoc_request_to_landing_tables; Type: ACL; Schema: data; Owner: ark_admin
--

REVOKE ALL ON TABLE assoc_request_to_landing_tables FROM PUBLIC;
REVOKE ALL ON TABLE assoc_request_to_landing_tables FROM ark_admin;
GRANT ALL ON TABLE assoc_request_to_landing_tables TO ark_admin;


--
-- TOC entry 2603 (class 0 OID 0)
-- Dependencies: 196
-- Name: assoc_user_to_loc; Type: ACL; Schema: data; Owner: ark_admin
--

REVOKE ALL ON TABLE assoc_user_to_loc FROM PUBLIC;
REVOKE ALL ON TABLE assoc_user_to_loc FROM ark_admin;
GRANT ALL ON TABLE assoc_user_to_loc TO ark_admin;
GRANT SELECT,INSERT,DELETE ON TABLE assoc_user_to_loc TO web_users;


--
-- TOC entry 2604 (class 0 OID 0)
-- Dependencies: 198
-- Name: assoc_user_to_water_color; Type: ACL; Schema: data; Owner: ark_admin
--

REVOKE ALL ON TABLE assoc_user_to_water_color FROM PUBLIC;
REVOKE ALL ON TABLE assoc_user_to_water_color FROM ark_admin;
GRANT ALL ON TABLE assoc_user_to_water_color TO ark_admin;
GRANT SELECT,INSERT,DELETE ON TABLE assoc_user_to_water_color TO web_users;


--
-- TOC entry 2613 (class 0 OID 0)
-- Dependencies: 179
-- Name: list_locations; Type: ACL; Schema: data; Owner: ark_admin
--

REVOKE ALL ON TABLE list_locations FROM PUBLIC;
REVOKE ALL ON TABLE list_locations FROM ark_admin;
GRANT ALL ON TABLE list_locations TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE list_locations TO web_users;


--
-- TOC entry 2615 (class 0 OID 0)
-- Dependencies: 178
-- Name: list_locations_loc_ndx_seq; Type: ACL; Schema: data; Owner: ark_admin
--

REVOKE ALL ON SEQUENCE list_locations_loc_ndx_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE list_locations_loc_ndx_seq FROM ark_admin;
GRANT ALL ON SEQUENCE list_locations_loc_ndx_seq TO ark_admin;
GRANT SELECT,UPDATE ON SEQUENCE list_locations_loc_ndx_seq TO web_users;


--
-- TOC entry 2617 (class 0 OID 0)
-- Dependencies: 181
-- Name: list_ownerentities; Type: ACL; Schema: data; Owner: ark_admin
--

REVOKE ALL ON TABLE list_ownerentities FROM PUBLIC;
REVOKE ALL ON TABLE list_ownerentities FROM ark_admin;
GRANT ALL ON TABLE list_ownerentities TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE list_ownerentities TO web_users;


--
-- TOC entry 2619 (class 0 OID 0)
-- Dependencies: 180
-- Name: list_ownerentities_own_ndx_seq; Type: ACL; Schema: data; Owner: ark_admin
--

REVOKE ALL ON SEQUENCE list_ownerentities_own_ndx_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE list_ownerentities_own_ndx_seq FROM ark_admin;
GRANT ALL ON SEQUENCE list_ownerentities_own_ndx_seq TO ark_admin;
GRANT SELECT,UPDATE ON SEQUENCE list_ownerentities_own_ndx_seq TO web_users;


--
-- TOC entry 2624 (class 0 OID 0)
-- Dependencies: 177
-- Name: list_users; Type: ACL; Schema: data; Owner: ark_admin
--

REVOKE ALL ON TABLE list_users FROM PUBLIC;
REVOKE ALL ON TABLE list_users FROM ark_admin;
GRANT ALL ON TABLE list_users TO ark_admin;
GRANT SELECT ON TABLE list_users TO web_users;


--
-- TOC entry 2626 (class 0 OID 0)
-- Dependencies: 187
-- Name: list_water_colors; Type: ACL; Schema: data; Owner: ark_admin
--

REVOKE ALL ON TABLE list_water_colors FROM PUBLIC;
REVOKE ALL ON TABLE list_water_colors FROM ark_admin;
GRANT ALL ON TABLE list_water_colors TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE list_water_colors TO web_users;


--
-- TOC entry 2628 (class 0 OID 0)
-- Dependencies: 186
-- Name: list_water_colors_wc_ndx_seq; Type: ACL; Schema: data; Owner: ark_admin
--

REVOKE ALL ON SEQUENCE list_water_colors_wc_ndx_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE list_water_colors_wc_ndx_seq FROM ark_admin;
GRANT ALL ON SEQUENCE list_water_colors_wc_ndx_seq TO ark_admin;
GRANT SELECT,UPDATE ON SEQUENCE list_water_colors_wc_ndx_seq TO web_users;


--
-- TOC entry 2630 (class 0 OID 0)
-- Dependencies: 223
-- Name: test_list_users; Type: ACL; Schema: data; Owner: ark_admin
--

REVOKE ALL ON TABLE test_list_users FROM PUBLIC;
REVOKE ALL ON TABLE test_list_users FROM ark_admin;
GRANT ALL ON TABLE test_list_users TO ark_admin;
GRANT SELECT,INSERT,DELETE ON TABLE test_list_users TO web_users;


SET search_path = tools, pg_catalog;

--
-- TOC entry 2631 (class 0 OID 0)
-- Dependencies: 241
-- Name: data_users_01; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE data_users_01 FROM PUBLIC;
REVOKE ALL ON TABLE data_users_01 FROM ark_admin;
GRANT ALL ON TABLE data_users_01 TO ark_admin;
GRANT SELECT ON TABLE data_users_01 TO web_users;


--
-- TOC entry 2632 (class 0 OID 0)
-- Dependencies: 253
-- Name: data_users_02_entities; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE data_users_02_entities FROM PUBLIC;
REVOKE ALL ON TABLE data_users_02_entities FROM ark_admin;
GRANT ALL ON TABLE data_users_02_entities TO ark_admin;
GRANT SELECT ON TABLE data_users_02_entities TO web_users;


--
-- TOC entry 2633 (class 0 OID 0)
-- Dependencies: 252
-- Name: data_users_03_locations; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE data_users_03_locations FROM PUBLIC;
REVOKE ALL ON TABLE data_users_03_locations FROM ark_admin;
GRANT ALL ON TABLE data_users_03_locations TO ark_admin;
GRANT SELECT ON TABLE data_users_03_locations TO web_users;


--
-- TOC entry 2634 (class 0 OID 0)
-- Dependencies: 251
-- Name: data_users_04_watercolors; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE data_users_04_watercolors FROM PUBLIC;
REVOKE ALL ON TABLE data_users_04_watercolors FROM ark_admin;
GRANT ALL ON TABLE data_users_04_watercolors TO ark_admin;
GRANT SELECT ON TABLE data_users_04_watercolors TO web_users;


--
-- TOC entry 2635 (class 0 OID 0)
-- Dependencies: 254
-- Name: data_users_associations_display_gviz; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE data_users_associations_display_gviz FROM PUBLIC;
REVOKE ALL ON TABLE data_users_associations_display_gviz FROM ark_admin;
GRANT ALL ON TABLE data_users_associations_display_gviz TO ark_admin;
GRANT SELECT ON TABLE data_users_associations_display_gviz TO web_users;


--
-- TOC entry 2636 (class 0 OID 0)
-- Dependencies: 267
-- Name: dd_locations; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE dd_locations FROM PUBLIC;
REVOKE ALL ON TABLE dd_locations FROM ark_admin;
GRANT ALL ON TABLE dd_locations TO ark_admin;
GRANT SELECT ON TABLE dd_locations TO web_users;


--
-- TOC entry 2637 (class 0 OID 0)
-- Dependencies: 245
-- Name: dd_users; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE dd_users FROM PUBLIC;
REVOKE ALL ON TABLE dd_users FROM ark_admin;
GRANT ALL ON TABLE dd_users TO ark_admin;
GRANT SELECT ON TABLE dd_users TO web_users;


--
-- TOC entry 2638 (class 0 OID 0)
-- Dependencies: 269
-- Name: egrid_assoc_locations_and_water_colors; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE egrid_assoc_locations_and_water_colors FROM PUBLIC;
REVOKE ALL ON TABLE egrid_assoc_locations_and_water_colors FROM ark_admin;
GRANT ALL ON TABLE egrid_assoc_locations_and_water_colors TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE egrid_assoc_locations_and_water_colors TO web_users;


--
-- TOC entry 2639 (class 0 OID 0)
-- Dependencies: 278
-- Name: egrid_assoc_triple_users_locs_wcs; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE egrid_assoc_triple_users_locs_wcs FROM PUBLIC;
REVOKE ALL ON TABLE egrid_assoc_triple_users_locs_wcs FROM ark_admin;
GRANT ALL ON TABLE egrid_assoc_triple_users_locs_wcs TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE egrid_assoc_triple_users_locs_wcs TO web_users;


--
-- TOC entry 2640 (class 0 OID 0)
-- Dependencies: 272
-- Name: egrid_assoc_users_and_entities; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE egrid_assoc_users_and_entities FROM PUBLIC;
REVOKE ALL ON TABLE egrid_assoc_users_and_entities FROM ark_admin;
GRANT ALL ON TABLE egrid_assoc_users_and_entities TO ark_admin;
GRANT SELECT ON TABLE egrid_assoc_users_and_entities TO web_users;


--
-- TOC entry 2641 (class 0 OID 0)
-- Dependencies: 268
-- Name: fetchit_landing_selected_loc_for_wc_assoc; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE fetchit_landing_selected_loc_for_wc_assoc FROM PUBLIC;
REVOKE ALL ON TABLE fetchit_landing_selected_loc_for_wc_assoc FROM ark_admin;
GRANT ALL ON TABLE fetchit_landing_selected_loc_for_wc_assoc TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE fetchit_landing_selected_loc_for_wc_assoc TO web_users;


--
-- TOC entry 2642 (class 0 OID 0)
-- Dependencies: 270
-- Name: egrid_build_assoc_locations_and_water_colors; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE egrid_build_assoc_locations_and_water_colors FROM PUBLIC;
REVOKE ALL ON TABLE egrid_build_assoc_locations_and_water_colors FROM ark_admin;
GRANT ALL ON TABLE egrid_build_assoc_locations_and_water_colors TO ark_admin;
GRANT SELECT ON TABLE egrid_build_assoc_locations_and_water_colors TO web_users;


--
-- TOC entry 2643 (class 0 OID 0)
-- Dependencies: 246
-- Name: fetchit_landing_selected_user_selectall; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE fetchit_landing_selected_user_selectall FROM PUBLIC;
REVOKE ALL ON TABLE fetchit_landing_selected_user_selectall FROM ark_admin;
GRANT ALL ON TABLE fetchit_landing_selected_user_selectall TO ark_admin;
GRANT ALL ON TABLE fetchit_landing_selected_user_selectall TO web_users;


--
-- TOC entry 2644 (class 0 OID 0)
-- Dependencies: 249
-- Name: fetchit_landing_selected_user_selectnone; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE fetchit_landing_selected_user_selectnone FROM PUBLIC;
REVOKE ALL ON TABLE fetchit_landing_selected_user_selectnone FROM ark_admin;
GRANT ALL ON TABLE fetchit_landing_selected_user_selectnone TO ark_admin;
GRANT ALL ON TABLE fetchit_landing_selected_user_selectnone TO web_users;


--
-- TOC entry 2645 (class 0 OID 0)
-- Dependencies: 247
-- Name: fetchit_landing_selected_user_to_manage; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE fetchit_landing_selected_user_to_manage FROM PUBLIC;
REVOKE ALL ON TABLE fetchit_landing_selected_user_to_manage FROM ark_admin;
GRANT ALL ON TABLE fetchit_landing_selected_user_to_manage TO ark_admin;
GRANT ALL ON TABLE fetchit_landing_selected_user_to_manage TO web_users;


--
-- TOC entry 2646 (class 0 OID 0)
-- Dependencies: 250
-- Name: fetchit_landing_user_to_manage_last_submit; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE fetchit_landing_user_to_manage_last_submit FROM PUBLIC;
REVOKE ALL ON TABLE fetchit_landing_user_to_manage_last_submit FROM ark_admin;
GRANT ALL ON TABLE fetchit_landing_user_to_manage_last_submit TO ark_admin;
GRANT SELECT ON TABLE fetchit_landing_user_to_manage_last_submit TO web_users;


--
-- TOC entry 2647 (class 0 OID 0)
-- Dependencies: 271
-- Name: egrid_build_assoc_users_and_entities; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE egrid_build_assoc_users_and_entities FROM PUBLIC;
REVOKE ALL ON TABLE egrid_build_assoc_users_and_entities FROM ark_admin;
GRANT ALL ON TABLE egrid_build_assoc_users_and_entities TO ark_admin;
GRANT SELECT ON TABLE egrid_build_assoc_users_and_entities TO web_users;


--
-- TOC entry 2648 (class 0 OID 0)
-- Dependencies: 262
-- Name: egrid_list_locations_add_new; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE egrid_list_locations_add_new FROM PUBLIC;
REVOKE ALL ON TABLE egrid_list_locations_add_new FROM ark_admin;
GRANT ALL ON TABLE egrid_list_locations_add_new TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE egrid_list_locations_add_new TO web_users;


--
-- TOC entry 2649 (class 0 OID 0)
-- Dependencies: 264
-- Name: egrid_list_locations_edit_delete; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE egrid_list_locations_edit_delete FROM PUBLIC;
REVOKE ALL ON TABLE egrid_list_locations_edit_delete FROM ark_admin;
GRANT ALL ON TABLE egrid_list_locations_edit_delete TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE egrid_list_locations_edit_delete TO web_users;


--
-- TOC entry 2650 (class 0 OID 0)
-- Dependencies: 261
-- Name: egrid_list_ownerentities_add_new; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE egrid_list_ownerentities_add_new FROM PUBLIC;
REVOKE ALL ON TABLE egrid_list_ownerentities_add_new FROM ark_admin;
GRANT ALL ON TABLE egrid_list_ownerentities_add_new TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE egrid_list_ownerentities_add_new TO web_users;


--
-- TOC entry 2651 (class 0 OID 0)
-- Dependencies: 263
-- Name: egrid_list_ownerentities_edit_delete; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE egrid_list_ownerentities_edit_delete FROM PUBLIC;
REVOKE ALL ON TABLE egrid_list_ownerentities_edit_delete FROM ark_admin;
GRANT ALL ON TABLE egrid_list_ownerentities_edit_delete TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE egrid_list_ownerentities_edit_delete TO web_users;


--
-- TOC entry 2652 (class 0 OID 0)
-- Dependencies: 266
-- Name: egrid_list_water_colors_add_new; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE egrid_list_water_colors_add_new FROM PUBLIC;
REVOKE ALL ON TABLE egrid_list_water_colors_add_new FROM ark_admin;
GRANT ALL ON TABLE egrid_list_water_colors_add_new TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE egrid_list_water_colors_add_new TO web_users;


--
-- TOC entry 2653 (class 0 OID 0)
-- Dependencies: 265
-- Name: egrid_list_water_colors_edit_delete; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE egrid_list_water_colors_edit_delete FROM PUBLIC;
REVOKE ALL ON TABLE egrid_list_water_colors_edit_delete FROM ark_admin;
GRANT ALL ON TABLE egrid_list_water_colors_edit_delete TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE egrid_list_water_colors_edit_delete TO web_users;


--
-- TOC entry 2654 (class 0 OID 0)
-- Dependencies: 274
-- Name: fetchit_landing_selected_loc_for_user_wc_triple_assoc; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE fetchit_landing_selected_loc_for_user_wc_triple_assoc FROM PUBLIC;
REVOKE ALL ON TABLE fetchit_landing_selected_loc_for_user_wc_triple_assoc FROM ark_admin;
GRANT ALL ON TABLE fetchit_landing_selected_loc_for_user_wc_triple_assoc TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE fetchit_landing_selected_loc_for_user_wc_triple_assoc TO web_users;


--
-- TOC entry 2655 (class 0 OID 0)
-- Dependencies: 280
-- Name: fetchit_landing_selected_wc_for_user_loc_triple_assoc; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE fetchit_landing_selected_wc_for_user_loc_triple_assoc FROM PUBLIC;
REVOKE ALL ON TABLE fetchit_landing_selected_wc_for_user_loc_triple_assoc FROM ark_admin;
GRANT ALL ON TABLE fetchit_landing_selected_wc_for_user_loc_triple_assoc TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE fetchit_landing_selected_wc_for_user_loc_triple_assoc TO web_users;


--
-- TOC entry 2656 (class 0 OID 0)
-- Dependencies: 279
-- Name: table_display_build_assoc_triple_users_locs_wcs_prep; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE table_display_build_assoc_triple_users_locs_wcs_prep FROM PUBLIC;
REVOKE ALL ON TABLE table_display_build_assoc_triple_users_locs_wcs_prep FROM ark_admin;
GRANT ALL ON TABLE table_display_build_assoc_triple_users_locs_wcs_prep TO ark_admin;
GRANT SELECT ON TABLE table_display_build_assoc_triple_users_locs_wcs_prep TO web_users;


--
-- TOC entry 2657 (class 0 OID 0)
-- Dependencies: 281
-- Name: table_display_build_assoc_triple_users_locs_wcs; Type: ACL; Schema: tools; Owner: ark_admin
--

REVOKE ALL ON TABLE table_display_build_assoc_triple_users_locs_wcs FROM PUBLIC;
REVOKE ALL ON TABLE table_display_build_assoc_triple_users_locs_wcs FROM ark_admin;
GRANT ALL ON TABLE table_display_build_assoc_triple_users_locs_wcs TO ark_admin;
GRANT SELECT ON TABLE table_display_build_assoc_triple_users_locs_wcs TO web_users;


SET search_path = web, pg_catalog;

--
-- TOC entry 2658 (class 0 OID 0)
-- Dependencies: 260
-- Name: assoc_request_to_landing_tables_view; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE assoc_request_to_landing_tables_view FROM PUBLIC;
REVOKE ALL ON TABLE assoc_request_to_landing_tables_view FROM ark_admin;
GRANT ALL ON TABLE assoc_request_to_landing_tables_view TO ark_admin;
GRANT SELECT ON TABLE assoc_request_to_landing_tables_view TO web_users;


--
-- TOC entry 2659 (class 0 OID 0)
-- Dependencies: 227
-- Name: exchange_from_locs_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE exchange_from_locs_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE exchange_from_locs_dropdown FROM ark_admin;
GRANT ALL ON TABLE exchange_from_locs_dropdown TO ark_admin;
GRANT SELECT ON TABLE exchange_from_locs_dropdown TO web_users;


--
-- TOC entry 2660 (class 0 OID 0)
-- Dependencies: 237
-- Name: exchange_from_loctype_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE exchange_from_loctype_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE exchange_from_loctype_dropdown FROM ark_admin;
GRANT ALL ON TABLE exchange_from_loctype_dropdown TO ark_admin;
GRANT SELECT ON TABLE exchange_from_loctype_dropdown TO web_users;


--
-- TOC entry 2661 (class 0 OID 0)
-- Dependencies: 233
-- Name: exchange_from_owners_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE exchange_from_owners_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE exchange_from_owners_dropdown FROM ark_admin;
GRANT ALL ON TABLE exchange_from_owners_dropdown TO ark_admin;
GRANT SELECT ON TABLE exchange_from_owners_dropdown TO web_users;


--
-- TOC entry 2662 (class 0 OID 0)
-- Dependencies: 243
-- Name: exchange_from_wc_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE exchange_from_wc_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE exchange_from_wc_dropdown FROM ark_admin;
GRANT ALL ON TABLE exchange_from_wc_dropdown TO ark_admin;
GRANT SELECT ON TABLE exchange_from_wc_dropdown TO web_users;


--
-- TOC entry 2663 (class 0 OID 0)
-- Dependencies: 226
-- Name: exchange_to_locs_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE exchange_to_locs_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE exchange_to_locs_dropdown FROM ark_admin;
GRANT ALL ON TABLE exchange_to_locs_dropdown TO ark_admin;
GRANT SELECT ON TABLE exchange_to_locs_dropdown TO web_users;


--
-- TOC entry 2664 (class 0 OID 0)
-- Dependencies: 236
-- Name: exchange_to_loctype_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE exchange_to_loctype_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE exchange_to_loctype_dropdown FROM ark_admin;
GRANT ALL ON TABLE exchange_to_loctype_dropdown TO ark_admin;
GRANT SELECT ON TABLE exchange_to_loctype_dropdown TO web_users;


--
-- TOC entry 2665 (class 0 OID 0)
-- Dependencies: 232
-- Name: exchange_to_owners_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE exchange_to_owners_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE exchange_to_owners_dropdown FROM ark_admin;
GRANT ALL ON TABLE exchange_to_owners_dropdown TO ark_admin;
GRANT SELECT ON TABLE exchange_to_owners_dropdown TO web_users;


--
-- TOC entry 2666 (class 0 OID 0)
-- Dependencies: 244
-- Name: exchange_to_wc_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE exchange_to_wc_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE exchange_to_wc_dropdown FROM ark_admin;
GRANT ALL ON TABLE exchange_to_wc_dropdown TO ark_admin;
GRANT SELECT ON TABLE exchange_to_wc_dropdown TO web_users;


--
-- TOC entry 2680 (class 0 OID 0)
-- Dependencies: 230
-- Name: landing_form1; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE landing_form1 FROM PUBLIC;
REVOKE ALL ON TABLE landing_form1 FROM ark_admin;
GRANT ALL ON TABLE landing_form1 TO ark_admin;
GRANT SELECT,INSERT,UPDATE ON TABLE landing_form1 TO web_users;


--
-- TOC entry 2681 (class 0 OID 0)
-- Dependencies: 242
-- Name: landing_form1_json; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE landing_form1_json FROM PUBLIC;
REVOKE ALL ON TABLE landing_form1_json FROM ark_admin;
GRANT ALL ON TABLE landing_form1_json TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE landing_form1_json TO web_users;


--
-- TOC entry 2683 (class 0 OID 0)
-- Dependencies: 229
-- Name: landing_form1_landing_ndx_seq; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON SEQUENCE landing_form1_landing_ndx_seq FROM PUBLIC;
REVOKE ALL ON SEQUENCE landing_form1_landing_ndx_seq FROM ark_admin;
GRANT ALL ON SEQUENCE landing_form1_landing_ndx_seq TO ark_admin;
GRANT ALL ON SEQUENCE landing_form1_landing_ndx_seq TO web_users;


--
-- TOC entry 2687 (class 0 OID 0)
-- Dependencies: 276
-- Name: landing_request_cancellation; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE landing_request_cancellation FROM PUBLIC;
REVOKE ALL ON TABLE landing_request_cancellation FROM ark_admin;
GRANT ALL ON TABLE landing_request_cancellation TO ark_admin;
GRANT SELECT,INSERT,UPDATE ON TABLE landing_request_cancellation TO web_users;


--
-- TOC entry 2707 (class 0 OID 0)
-- Dependencies: 239
-- Name: landing_request_exchange; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE landing_request_exchange FROM PUBLIC;
REVOKE ALL ON TABLE landing_request_exchange FROM ark_admin;
GRANT ALL ON TABLE landing_request_exchange TO ark_admin;
GRANT SELECT,INSERT,UPDATE ON TABLE landing_request_exchange TO web_users;


--
-- TOC entry 2708 (class 0 OID 0)
-- Dependencies: 256
-- Name: landing_request_exchange_json; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE landing_request_exchange_json FROM PUBLIC;
REVOKE ALL ON TABLE landing_request_exchange_json FROM ark_admin;
GRANT ALL ON TABLE landing_request_exchange_json TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE landing_request_exchange_json TO web_users;


--
-- TOC entry 2709 (class 0 OID 0)
-- Dependencies: 273
-- Name: landing_request_exchange_secondary; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE landing_request_exchange_secondary FROM PUBLIC;
REVOKE ALL ON TABLE landing_request_exchange_secondary FROM ark_admin;
GRANT ALL ON TABLE landing_request_exchange_secondary TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE landing_request_exchange_secondary TO web_users;


--
-- TOC entry 2710 (class 0 OID 0)
-- Dependencies: 275
-- Name: landing_request_exchange_secondary_json; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE landing_request_exchange_secondary_json FROM PUBLIC;
REVOKE ALL ON TABLE landing_request_exchange_secondary_json FROM ark_admin;
GRANT ALL ON TABLE landing_request_exchange_secondary_json TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE landing_request_exchange_secondary_json TO web_users;


--
-- TOC entry 2723 (class 0 OID 0)
-- Dependencies: 231
-- Name: landing_request_reservoir; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE landing_request_reservoir FROM PUBLIC;
REVOKE ALL ON TABLE landing_request_reservoir FROM ark_admin;
GRANT ALL ON TABLE landing_request_reservoir TO ark_admin;
GRANT SELECT,INSERT,UPDATE ON TABLE landing_request_reservoir TO web_users;


--
-- TOC entry 2724 (class 0 OID 0)
-- Dependencies: 255
-- Name: landing_request_reservoir_json; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE landing_request_reservoir_json FROM PUBLIC;
REVOKE ALL ON TABLE landing_request_reservoir_json FROM ark_admin;
GRANT ALL ON TABLE landing_request_reservoir_json TO ark_admin;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE landing_request_reservoir_json TO web_users;


--
-- TOC entry 2725 (class 0 OID 0)
-- Dependencies: 240
-- Name: list_users_and_owners_view; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE list_users_and_owners_view FROM PUBLIC;
REVOKE ALL ON TABLE list_users_and_owners_view FROM ark_admin;
GRANT ALL ON TABLE list_users_and_owners_view TO ark_admin;
GRANT SELECT ON TABLE list_users_and_owners_view TO web_users;


--
-- TOC entry 2726 (class 0 OID 0)
-- Dependencies: 248
-- Name: list_users_view; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE list_users_view FROM PUBLIC;
REVOKE ALL ON TABLE list_users_view FROM ark_admin;
GRANT ALL ON TABLE list_users_view TO ark_admin;
GRANT SELECT ON TABLE list_users_view TO web_users;


--
-- TOC entry 2727 (class 0 OID 0)
-- Dependencies: 234
-- Name: request_type_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE request_type_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE request_type_dropdown FROM ark_admin;
GRANT ALL ON TABLE request_type_dropdown TO ark_admin;
GRANT SELECT ON TABLE request_type_dropdown TO web_users;


--
-- TOC entry 2728 (class 0 OID 0)
-- Dependencies: 235
-- Name: reservoir_release_loctype_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE reservoir_release_loctype_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE reservoir_release_loctype_dropdown FROM ark_admin;
GRANT ALL ON TABLE reservoir_release_loctype_dropdown TO ark_admin;
GRANT SELECT ON TABLE reservoir_release_loctype_dropdown TO web_users;


--
-- TOC entry 2729 (class 0 OID 0)
-- Dependencies: 225
-- Name: reservoir_release_res_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE reservoir_release_res_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE reservoir_release_res_dropdown FROM ark_admin;
GRANT ALL ON TABLE reservoir_release_res_dropdown TO ark_admin;
GRANT SELECT ON TABLE reservoir_release_res_dropdown TO web_users;


--
-- TOC entry 2730 (class 0 OID 0)
-- Dependencies: 224
-- Name: reservoir_release_wc_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE reservoir_release_wc_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE reservoir_release_wc_dropdown FROM ark_admin;
GRANT ALL ON TABLE reservoir_release_wc_dropdown TO ark_admin;
GRANT SELECT ON TABLE reservoir_release_wc_dropdown TO web_users;


--
-- TOC entry 2731 (class 0 OID 0)
-- Dependencies: 238
-- Name: units_dropdown; Type: ACL; Schema: web; Owner: ark_admin
--

REVOKE ALL ON TABLE units_dropdown FROM PUBLIC;
REVOKE ALL ON TABLE units_dropdown FROM ark_admin;
GRANT ALL ON TABLE units_dropdown TO ark_admin;
GRANT SELECT ON TABLE units_dropdown TO web_users;


-- Completed on 2018-03-27 20:43:57

--
-- PostgreSQL database dump complete
--

