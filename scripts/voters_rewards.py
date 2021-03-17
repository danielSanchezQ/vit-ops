from typing import List, Union

import yaml
import pydantic


class Stake(pydantic.BaseModel):
    address: str
    value: int


class Fund(pydantic.BaseModel):
    fund: List[Stake]


class BlockchainConfiguration(pydantic.BaseModel):
    committees: List[str]


class Cert(pydantic.BaseModel):
    cert: str


class Block0(pydantic.BaseModel):
    blockchain_configuration: BlockchainConfiguration
    initial: List[Union[Fund, Cert]]


def load_block0(block0_file_path: str) -> Block0:
    with open(block0_file_path, encoding="utf-16") as f:
        return Block0(**yaml.load(f, Loader=yaml.FullLoader))


if __name__ == "__main__":
    from pprint import pprint
    block0 = load_block0("../block0test.yaml")
    pprint(block0.initial[:10])
