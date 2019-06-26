
Working with Jupyter notebooks.


Launch a Jupyter notebook from a remote cluster
-----------------------------------------------

```bash
# from remote cluster (e.g., a virtual machine) enter:
jupyter notebook --no-browser --port=8889

# from local terminal enter
ssh -N -L localhost:8888:localhost:8889 my_user_name@my_remote_cluster

# from browser go to the link below and enter token from remote session
http://localhost:8888
```
