SELECT results_eq(
    $$ SELECT sort_sqlorderby('{"sortby":{"field":"properties.eo:cloud_cover"}}'); $$,
    $$ SELECT sort_sqlorderby('{"sortby":{"field":"eo:cloud_cover"}}'); $$,
    'Make sure that sortby with/without properties prefix return the same sort statement.'
);

SET pgstac."default_filter_lang" TO 'cql2-json';

SELECT results_eq(
    $$ SELECT stac_search_to_where('{"filter":{"op":"eq","args":[{"property":"eo:cloud_cover"},0]}}'); $$,
    $$ SELECT stac_search_to_where('{"filter":{"op":"eq","args":[{"property":"properties.eo:cloud_cover"},0]}}'); $$,
    'Make sure that CQL2 filter works the same with/without properties prefix.'
);

SET pgstac."default_filter_lang" TO 'cql-json';

SELECT results_eq(
    $$ SELECT stac_search_to_where('{"filter":{"eq":[{"property":"eo:cloud_cover"},0]}}'); $$,
    $$ SELECT stac_search_to_where('{"filter":{"eq":[{"property":"properties.eo:cloud_cover"},0]}}'); $$,
    'Make sure that CQL filter works the same with/without properties prefix.'
);

DELETE FROM collections WHERE id in ('pgstac-test-collection', 'pgstac-test-collection2');
\copy collections (content) FROM 'tests/testdata/collections.ndjson';

SELECT results_eq(
    $$ SELECT get_queryables('pgstac-test-collection') -> 'properties' ? 'datetime'; $$,
    $$ SELECT true; $$,
    'Make sure valid schema object is returned for a existing collection.'
);

SELECT results_eq(
    $$ SELECT get_queryables('foo'); $$,
    $$ SELECT NULL::jsonb; $$,
    'Make sure null is returned for a non-existant collection.'
);

SELECT lives_ok(
    $$ DELETE FROM queryables WHERE name IN ('testqueryable', 'testqueryable2', 'testqueryable3'); $$,
    'Make sure test queryable does not exist.'
);

SELECT lives_ok(
    $$ INSERT INTO queryables (name, collection_ids) VALUES ('testqueryable', null); $$,
    'Can add a new queryable that applies to all collections.'
);

select is(
    (SELECT count(*) from collections where id = 'pgstac-test-collection'),
    '1',
    'Make sure test collection exists.'
);

SELECT lives_ok(
    $$ INSERT INTO queryables (name, collection_ids) VALUES ('testqueryable3', '{pgstac-test-collection}'); $$,
    'Can add a new queryable to a specific existing collection.'
);

SELECT throws_ok(
    $$ INSERT INTO queryables (name, collection_ids) VALUES ('testqueryable2', '{nonexistent}'); $$,
    '23503'
);

SELECT throws_ok(
    $$ INSERT INTO queryables (name, collection_ids) VALUES ('testqueryable', '{pgstac-test-collection}'); $$,
    '23505'
);

SELECT lives_ok(
    $$ UPDATE queryables SET collection_ids = '{pgstac-test-collection}' WHERE name='testqueryable'; $$,
    'Can update a queryable from null to a single collection.'
);
