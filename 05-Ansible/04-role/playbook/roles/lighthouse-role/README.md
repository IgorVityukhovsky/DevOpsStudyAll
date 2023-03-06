Role Name
=========

lighthouse-role

Requirements
------------
```yaml
---
  - src: git@github.com:IgorVityukhovsky/lighthouse-role.git
    scm: git
    version: "latest"
    name: lighthouse-role
```

Role Variables
--------------
```
lighthouse_repo: https://github.com/VKCOM/lighthouse.git   <--- default
```

Dependencies
------------

В роль включена установка nginx 

Example Playbook
----------------

    - hosts: servers
      roles:
         - role: lighthouse-role

License
-------

BSD

Author Information
------------------

IgorVityukhovsky  
relixinus@mail.ru
