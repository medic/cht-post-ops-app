# CHT Post-Ops App
## Setting up
### CHT instance
Use this guide if you need a development CHT instance.

#### Clone the repository
Use `git clone` to get a local copy of the repository:

`git clone https://github.com/medic/cht-post-ops-app.git`

#### Install dependencies
Change to the project directory and install npm dependencies using

`npm install`
### Upload configuration

Use the [CHT app configurer](https://github.com/medic/cht-conf) to upload the configuration to a CHT instance running [CHT core](https://github.com/medic/cht-core). To set up CHT app configurer, the following steps are required:

#### cht-conf

```
npm install -g cht-conf
```

#### pyxform

`pyxform` is a python package used for creating XForms. Installation is operating system specific as detailed below:

###### Ubuntu

```
sudo python -m pip install git+https://github.com/medic/pyxform.git@medic-conf-1.17#egg=pyxform-medic
```

###### Windows

```
python -m pip install git+https://github.com/medic/pyxform.git@medic-conf-1.17#egg=pyxform-medic --upgrade
```

###### OSX

```
pip install git+https://github.com/medic/pyxform.git@medic-conf-1.17#egg=pyxform-medic
```

#### upload configuration

###### localhost

Use this command if the instance URL is defined in the COUCH_URL environment variable.

```
cht --local
```

###### arbitrary URL

```
cht --url=https://username:password@example.com:12345
```

## Documentation

Supported use-cases:

## Contributing

Contributions are welcome! Read about how to contribute on the [documentation site](https://docs.communityhealthtoolkit.org/contribute/).

## License

The software is provided under AGPL-3.0. Contributions to this project are accepted under the same license.
