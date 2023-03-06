Role Name
=========

vector-role

Requirements
------------

```yaml
---
  - src: git@github.com:IgorVityukhovsky/vector-role.git
    scm: git
    version: "0.25.1"
    name: vector-role
```

Role Variables
--------------
```
vector_version: '0.25.1'. <-- default  

vector_package: 'vector-{{ vector_version }}.rpm'  
vector_url: 'https://packages.timber.io/vector/{{ vector_version }}/vector-{{ vector_version }}-1.x86_64.rpm'  
```

Dependencies
------------


Example Playbook
----------------

    - hosts: servers
      roles:
         - role: vector-role

License
-------

BSD

Author Information
------------------
IgorVityukhovsky
relixinis@mail.ru
