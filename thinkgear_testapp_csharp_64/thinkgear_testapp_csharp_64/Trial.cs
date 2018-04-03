using System;

public class Trial {
    public String id;
    public int status;
    public float raw;
    public int trial;
    public int packet;
    public DateTime time;

    public Trial(String id, int status, int trial, float raw, int packet, DateTime time) {
        this.id = id;
        this.status = status;
        this.raw = raw;
        this.trial = trial;
        this.packet = packet;
        this.time = time;
    }

    public override string ToString() {
        return (this.id + "," + this.status + "," + this.trial + "," + this.packet + "," + this.raw + "," + this.time);
    }
}