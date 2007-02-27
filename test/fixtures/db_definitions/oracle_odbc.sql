create table companies (
    id number(10) not null,
    type varchar(50) default null,
    ruby_type varchar(50) default null,
    firm_id number(10) default null references companies initially deferred disable,
    name varchar(50) default null,
    client_of number(10) default null references companies initially deferred disable,
    companies_count number(10) default 0,
    rating number(10) default 1,
    primary key (id)
);

-- non-standard sequence name used to test set_sequence_name
--
create sequence companies_nonstd_seq minvalue 10000;

create table funny_jokes (
  id number(10) not null,
  name varchar(50) default null,
  primary key (id)
);
create sequence funny_jokes_seq minvalue 10000;

create table accounts (
    id number(10) not null,
    firm_id number(10) default null references companies initially deferred disable,
    credit_limit number(10) default null
);
create sequence accounts_seq minvalue 10000;

create table topics (
    id number(10) not null,
    title varchar(255) default null,
    author_name varchar(255) default null,
    author_email_address varchar(255) default null,
    written_on timestamp default null,
    bonus_time timestamp default null,
    last_read timestamp default null,
    content varchar(4000),
    approved number(1) default 1,
    replies_count number(10) default 0,
    parent_id number(10) references topics initially deferred disable,
    type varchar(50) default null,
    primary key (id)
);
create sequence topics_seq minvalue 10000;

create synonym subjects for topics;

create table developers (
    id number(10) not null,
    name varchar(100) default null,
    salary number(10) default 70000,
    created_at timestamp default null,
    updated_at timestamp default null,
    primary key (id)
);
create sequence developers_seq minvalue 10000;

create table projects (
    id number(10) not null,
    name varchar(100) default null,
    type varchar(255) default null,
    primary key (id)
);
create sequence projects_seq minvalue 10000;

create table developers_projects (
    developer_id number(10) not null references developers initially deferred disable,
    project_id number(10) not null references projects initially deferred disable,
    joined_on timestamp default null,
    access_level number(10) default 1
);
create sequence developers_projects_seq minvalue 10000;

create table orders (
    id number(10) not null,
    name varchar(100) default null,
    billing_customer_id number(10) default null,
    shipping_customer_id number(10) default null,
    primary key (id)
);
create sequence orders_seq minvalue 10000;

create table customers (
    id number(10) not null,
    name varchar(100) default null,
    balance number(10) default 0,
    address_street varchar(100) default null,
    address_city varchar(100) default null,
    address_country varchar(100) default null,
    gps_location varchar(100) default null,
    primary key (id)
);
create sequence customers_seq minvalue 10000;

create table movies (
    movieid number(10) not null,
    name varchar(100) default null,
    primary key (movieid)
);
create sequence movies_seq minvalue 10000;

create table subscribers (
    nick varchar(100) not null,
    name varchar(100) default null,
    primary key (nick)
);
create sequence subscribers_seq minvalue 10000;

create table booleantests (
    id number(10) not null,
    value number(10) default null,
    primary key (id)
);
create sequence booleantests_seq minvalue 10000;

create table defaults (
    id number(10) not null,
    modified_date date default sysdate,
    modified_date_function date default sysdate,
    fixed_date date default to_date('2004-01-01', 'YYYY-MM-DD'),
    modified_time date default sysdate,
    modified_time_function date default sysdate,
    fixed_time date default TO_DATE('2004-01-01 00:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    char1 varchar2(1) default 'Y',
    char2 varchar2(50) default 'a varchar field',
    char3 clob default 'a text field',
    positive_integer number(10) default 1,
    negative_integer number(10) default -1,
    decimal_number number(3,2) default 2.78
);
create sequence defaults_seq minvalue 10000;

create table auto_id_tests (
    auto_id number(10) not null,
    value number(10) default null,
    primary key (auto_id)
);
create sequence auto_id_tests_seq minvalue 10000;

create table entrants (
    id number(10) not null primary key,
    name varchar(255) not null,
    course_id number(10) not null
);
create sequence entrants_seq minvalue 10000;

create table colnametests (
    id number(10) not null,
    references number(10) not null,
    primary key (id)
);
create sequence colnametests_seq minvalue 10000;

create table mixins (
    id number(10) not null,
    parent_id number(10) default null references mixins initially deferred disable,
    type varchar(40) default null,
    pos number(10) default null,
    lft number(10) default null,
    rgt number(10) default null,
    root_id number(10) default null,
    created_at timestamp default null,
    updated_at timestamp default null,
    primary key (id)
);
create sequence mixins_seq minvalue 10000;

create table people (
    id number(10) not null,
    first_name varchar(40) null,
    lock_version number(10) default 0,
    primary key (id)
);
create sequence people_seq minvalue 10000;

create table readers (
    id number(10) not null,
    post_id number(10) not null,
    person_id number(10) not null,
    primary key (id)
);
create sequence readers_seq minvalue 10000;

create table binaries (
    id number(10) not null,
    data blob null,
    primary key (id)
);
create sequence binaries_seq minvalue 10000;

create table computers (
  id number(10) not null primary key,
  developer number(10) not null references developers initially deferred disable,
  "extendedWarranty" number(10) not null
);
create sequence computers_seq minvalue 10000;

create table posts (
  id number(10) not null primary key,
  author_id number(10) default null,
  title varchar(255) default null,
  type varchar(255) default null,
  body varchar(3000) default null
);
create sequence posts_seq minvalue 10000;

create table comments (
  id number(10) not null primary key,
  post_id number(10) default null,
  type varchar(255) default null,
  body varchar(3000) default null
);
create sequence comments_seq minvalue 10000;

create table authors (
  id number(10) not null primary key,
  name varchar(255) default null
);
create sequence authors_seq minvalue 10000;

create table tasks (
  id number(10) not null primary key,
  starting date default null,
  ending date default null
);
create sequence tasks_seq minvalue 10000;

create table categories (
  id number(10) not null primary key,
  name varchar(255) default null,
  type varchar(255) default null
);
create sequence categories_seq minvalue 10000;

create table categories_posts (
  category_id number(10) not null references categories initially deferred disable,
  post_id number(10) not null references posts initially deferred disable
);
create sequence categories_posts_seq minvalue 10000;

create table fk_test_has_pk (
  id number(10) not null primary key
);
create sequence fk_test_has_pk_seq minvalue 10000;

create table fk_test_has_fk (
  id number(10) not null primary key,
  fk_id number(10) not null references fk_test_has_fk initially deferred disable
);
create sequence fk_test_has_fk_seq minvalue 10000;

create table keyboards (
  key_number number(10) not null,
  name varchar(50) default null
);
create sequence keyboards_seq minvalue 10000;

create table test_oracle_defaults (
  id number(10) not null primary key,
  test_char char(1) default 'X' not null,
  test_string varchar2(20) default 'hello' not null,
  test_int number(10) default 3 not null
);
create sequence test_oracle_defaults_seq minvalue 10000;

--This table has an altered lock_version column name.
create table legacy_things (
    id number(10) not null primary key,
    tps_report_number number(10) default null,
    version number(10) default 0
);
create sequence legacy_things_seq minvalue 10000;

create table numeric_data (
  id number(10) not null primary key,
  bank_balance decimal(10,2),
  big_bank_balance decimal(15,2),
  world_population decimal(10),
  my_house_population decimal(2),
  decimal_number_with_default decimal(3,2) default 2.78
);
create sequence numeric_data_seq minvalue 10000;

