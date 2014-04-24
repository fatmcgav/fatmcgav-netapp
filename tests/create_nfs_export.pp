netapp::create_nfs_export { 'nfsvol':
  size => '100g',
  aggr => 'aggr1',
  spaceres => 'none',
  snapresv  => 0,
  autoincrement => true,
  persistent => true ,
  path => $name,
  anon => '0' ,
  readonly => [],
  readwrite => ['all_hosts'] 
}
