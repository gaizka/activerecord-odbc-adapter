--Ensure environment variable DELIMIDENT=y

create table accounts (
  id serial primary key,
  firm_id int,
  credit_limit int
);

create table funny_jokes (
  id serial primary key,
  name varchar(50)
);

create table companies (
  id serial primary key,
  type varchar(50),
  ruby_type varchar(50),
  firm_id int,
  name varchar(50),
  client_of int,
  rating int default 1
);

create table topics (
  id serial primary key,
  title varchar(255),
  author_name varchar(255),
  author_email_address varchar(255),
  written_on datetime year to second,
  bonus_time datetime year to second,
  last_read date,
  content varchar(255),
  approved smallint default 1,
  replies_count int default 0,
  parent_id int,
  type varchar(50)
);

create table developers (
  id serial primary key,
  name varchar(100),
  salary int default 70000,
  created_at datetime year to second,
  updated_at datetime year to second 
);

create table projects (
  id serial primary key,
  name varchar(100),
  type varchar(255)
);

create table developers_projects (
  developer_id int not null,
  project_id int not null,
  joined_on date,
  access_level int default 1
);

create table orders (
  id serial primary key,
  name varchar(100),
  billing_customer_id int,
  shipping_customer_id int
);


create table customers (
  id serial primary key,
  name varchar(100),
  balance int default 0,
  address_street varchar(100),
  address_city varchar(100),
  address_country varchar(100),
  gps_location varchar(100)
);

create table movies (
  movieid serial primary key,
  name varchar(100)
);

create table subscribers (
  nick varchar(100) primary key,
  name varchar(100)
);

create table booleantests (
  id serial primary key,
  value smallint
);

create table auto_id_tests (
  auto_id serial primary key,
  value int
);

create table entrants (
  id int primary key,
  name varchar(255) not null,
  course_id int not null
);

create table colnametests (
  id serial primary key,
  "references" int not null
);

create table mixins (
  id serial primary key,
  parent_id int, 
  pos int,
  created_at datetime year to second,
  updated_at datetime year to second,
  lft int,
  rgt int,
  root_id int,
  type varchar(40)    
);

create table people (
  id serial,
  first_name varchar(40),
  lock_version int default 0,
  primary key (id)
);

create table readers (
    id serial,
    post_id int not null,
    person_id int not null,
    primary key (id)
);

create table binaries (
  id serial primary key,
  data byte
);

create table computers (
  id serial primary key,
  developer int not null,
  "extendedWarranty" int not null
);

create table posts (
  id serial primary key,
  author_id int,
  title varchar(255),
  type varchar(255),
  body lvarchar
);

create table comments (
  id serial primary key,
  post_id int,
  type varchar(255),
  body lvarchar
);

create table authors (
  id serial primary key,
  name varchar(255)
);

create table tasks (
  id serial primary key,
  starting datetime year to second,
  ending datetime year to second 
);

create table categories (
  id serial primary key,
  name varchar(255),
  type varchar(255)
);

create table categories_posts (
  category_id int not null,
  post_id int not null
);

create table fk_test_has_pk (
  id integer primary key
);

create table fk_test_has_fk (
  id    integer primary key,
  fk_id integer not null,

  foreign key (fk_id) references fk_test_has_pk(id)
);

create table keyboards (
  key_number serial primary key,
  name varchar(50)
);

--This table has an altered lock_version column name.
create table legacy_things (
  id serial,
  tps_report_number int,
  version int default 0,
  primary key (id)
);

create table numeric_data (
  id serial primary key,
  bank_balance decimal(10,2),
  big_bank_balance decimal(15,2),
  world_population decimal(10,0),
  my_house_population decimal(2,0),
  decimal_number_with_default decimal(3,2) DEFAULT 2.78
);

