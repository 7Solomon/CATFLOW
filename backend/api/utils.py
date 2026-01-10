from typing import List, Dict, Any, Union
import numpy as np
import pandas as pd

def numpy_to_list(arr: Union[np.ndarray, List]) -> List:
    """Recursively convert numpy arrays to lists"""
    if isinstance(arr, np.ndarray):
        return arr.tolist()
    if isinstance(arr, list):
        return [numpy_to_list(x) for x in arr]
    return arr

def dataframe_to_json(df: pd.DataFrame) -> Dict[str, Any]:
    """Convert DataFrame to a JSON-friendly format (split orientation)"""
    if df is None:
        return {}
    # Replaces Infinity and NaN with None for valid JSON
    df_clean = df.replace([np.inf, -np.inf], None).where(pd.notnull(df), None)
    return df_clean.to_dict(orient="split")
