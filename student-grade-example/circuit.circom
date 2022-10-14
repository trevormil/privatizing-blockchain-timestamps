pragma circom 2.0.0;


 
template Multiplier(n) {
    signal input xCommitments[n];
    signal input yCommitments[n];
    signal input timestamps[n];

    signal output c;

    signal int[n];

    signal a <== xCommitments[0];
    signal b <== yCommitments[0];

    int[0] <== a*a + b + 2;
    for (var i=1; i<n; i++) {
        int[i] <== int[i-1]*int[i-1] + b;
    }

    c <== int[n-1];
}

component main  {public [xCommitments, yCommitments, timestamps]}= Multiplier(3);
