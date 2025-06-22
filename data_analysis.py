import statistics as stat
import matplotlib.pyplot as plt
import numpy as np

small_runtimes = [
    0.856119857,
    0.301506129,
    0.479800106,
    3.513188998,
    0.357612453,
    0.188956827,
    0.210919241,
    0.734979118,
    0.204199869,
    1.068296348
]

medium_runtimes = [
    0.556968035,
    9.516877140,
    18.128718386,
    48.045638922,
    37.709424685,
    142.823683443,
    12.139918210,
    6.928462334,
    1.900516247,
    16.095675156
]

print("Mean of small runtimes: {}\nMedian of small runtimes {}\nStandard Deviation of small runtimes {}\n".format(stat.mean(small_runtimes), stat.median(small_runtimes), stat.stdev(small_runtimes)))

plt.scatter(np.arange(1, 11, 1), small_runtimes)
plt.show()
