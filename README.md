# Personal Health

A repository to track nutrition and biometric data from MyFitnessPal and Cronometer.
Historically I used MFP, but I found that the accuracy of the nutritional data varied drastically so I switched to Cronometer.
Neither platform makes it easy to extract and analyze your data, so I use the excellent [Python package by Adam Coddington](https://github.com/coddingtonbear/python-myfitnesspal) and [Go module by Jeremy Canaday](https://github.com/jrmycanady/gocronometer).
To automate the downloads and ensure I have the most up to date information, I have written a couple of naive python and shell scripts to check the last download date and for each source and download the data since.
I then run the data through a quick R analysis pipeline with [`{targets}`](https://github.com/ropensci/targets).

To do everything, all you have to do is run the following command:

```bash
zsh run.sh
```

If you find this useful, have any suggestions, or see any errors, please let me know!
