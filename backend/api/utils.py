from typing import List
import numpy as np

def numpy_to_list(arr: np.ndarray) -> List:
    """Recursively convert numpy arrays to lists"""
    if isinstance(arr, np.ndarray):
        return arr.tolist()
    return arr
