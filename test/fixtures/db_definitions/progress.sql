create table accounts (
  id integer not null primary key,
  firm_id integer,
  credit_limit integer
);
create sequence accounts_seq minvalue 10000;

create table authors (
  id integer not null primary key,
  name varchar(255)
);
create sequence authors_seq minvalue 10000;

create table auto_id_tests (
  auto_id integer not null primary key,
  value integer
);
create sequence auto_id_tests_seq minvalue 10000;

/*
 * lvarbinary type imposes many restrictions
 *
 * create table binaries (
 *   id integer not null primary key,
 *   data lvarbinary(1048576)
 * );
 * create sequence binaries_seq minvalue 10000;
 */

create table booleantests (
  id integer not null primary key,
  value integer
);
create sequence booleantests_seq minvalue 10000;

create table categories (
  id integer not null primary key,
  name varchar(255),
  "type" varchar(255)
);
create sequence categories_seq minvalue 10000;

create table categories_posts (
  category_id integer not null,
  post_id integer not null
);
create sequence categories_posts_seq minvalue 10000;

create table colnametests (
  id integer not null primary key,
  "references" integer not null
);
create sequence colnametests_seq minvalue 10000;

create table comments (
  id integer not null primary key,
  post_id integer,
  "type" varchar(255),
  body varchar(3000)
);
create sequence comments_seq minvalue 10000;

create table companies (
  id integer not null primary key,
  "type" varchar(50),
  ruby_type varchar(50),
  firm_id integer,
  name varchar(50),
  client_of integer,
  companies_count integer default 0,
  rating integer default 1
);
create sequence companies_seq minvalue 10000;

create table computers (
  id integer not null primary key,
  developer integer not null,
  "extendedWarranty" integer not null
);
create sequence computers_seq minvalue 10000;

create table customers (
  id integer not null primary key,
  name varchar(100),
  balance integer default 0,
  address_street varchar(100),
  address_city varchar(100),
  address_country varchar(100),
  gps_location varchar(100)
);
create sequence customers_seq minvalue 10000;

create table developers (
  id integer not null primary key,
  name varchar(100),
  salary integer default 70000,
  created_at timestamp,
  updated_at timestamp
);
create sequence developers_seq minvalue 10000;

create table developers_projects (
  developer_id integer not null,
  project_id integer not null,
  joined_on timestamp,
  access_level integer default 1
);
create sequence developers_projects_seq minvalue 10000;

create table entrants (
  id integer not null primary key,
  name varchar(255),
  course_id integer
);
create sequence entrants_seq minvalue 10000;

create table fk_test_has_fk (
  id integer not null primary key,
  fk_id integer not null
);
create sequence fk_test_has_fk_seq minvalue 10000;

create table fk_test_has_pk (
  id integer not null primary key
);
create sequence fk_test_has_pk_seq minvalue 10000;

create table funny_jokes (
  id integer not null primary key,
  name varchar(50)
);
create sequence funny_jokes_seq minvalue 10000;

create table keyboards (
  key_number integer not null primary key,
  name varchar(50)
);
create sequence keyboards_seq minvalue 10000;

/*
 * This table has an altered lock_version column name.
 */
create table legacy_things (
  id integer not null primary key,
  tps_report_number integer,
  version integer default 0
);
create sequence legacy_things_seq minvalue 10000;

create table mixins (
  id integer not null primary key,
  parent_id integer,
  "type" varchar(40),
  pos integer,
  lft integer,
  rgt integer,
  root_id integer,
  created_at timestamp,
  updated_at timestamp
);
create sequence mixins_seq minvalue 10000;

create table movies (
  movieid integer not null primary key,
  name varchar(100)
);
create sequence movies_seq minvalue 10000;

create table orders (
  id integer not null primary key,
  name varchar(100),
  billing_customer_id integer,
  shipping_customer_id integer
);
create sequence orders_seq minvalue 10000;

create table people (
  id integer not null primary key,
  first_name varchar(40) null,
  lock_version integer default 0
);
create sequence people_seq minvalue 10000;

create table posts (
  id integer not null primary key,
  author_id integer,
  title varchar(255),
  "type" varchar(255),
  body varchar(3000)
);
create sequence posts_seq minvalue 10000;

create table projects (
  id integer not null primary key,
  name varchar(100),
  "type" varchar(255)
);
create sequence projects_seq minvalue 10000;

create table readers (
  id integer not null primary key,
  post_id integer not null,
  person_id integer not null
);
create sequence readers_seq minvalue 10000;

create table subscribers (
  nick varchar(100) not null primary key,
  name varchar(100)
);
create sequence subscribers_seq minvalue 10000;

create table tasks (
  id integer not null primary key,
  starting date,
  ending date
);
create sequence tasks_seq minvalue 10000;

create table topics (
  id integer not null primary key,
  title varchar(255),
  author_name varchar(255),
  author_email_address varchar(255),
  written_on timestamp,
  bonus_time timestamp,
  last_read date,
  content varchar(4000),
  approved integer default 1,
  replies_count integer default 0,
  parent_id integer,
  "type" varchar(50)
);
create sequence topics_seq minvalue 10000;

create table numeric_data (
  id integer not null primary key,
  bank_balance decimal(10,2),
  big_bank_balance decimal(15,2),
  world_population decimal(10),
  my_house_population decimal(2),
  decimal_number_with_default decimal(3,2) default 2.78
);
create sequence numeric_data_seq minvalue 10000;

create table mixed_case_monkeys (
  "monkeyID" integer not null primary key,
  "fleaCount" integer
);
create sequence mixed_case_monkeys_seq minvalue 10000;

create table minimalistics (
  id integer not null primary key
);
create sequence minimalistics_seq minvalue 10000;
