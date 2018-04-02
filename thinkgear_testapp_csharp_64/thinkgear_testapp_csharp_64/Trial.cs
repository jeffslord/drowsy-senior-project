using System;

public class Trial
{
    public String id;
    public int status;
    public float raw;
    public int trial;
    public DateTime time;

	public Trial(String id, int status, float raw, int trial, DateTime time)
	{
        this.id = id;
        this.status = status;
        this.raw = raw;
        this.trial = trial;
        this.time = time;
	}

    public override string ToString()
    {
        return (this.id + "," + this.status + "," + this.raw + "," + this.trial + "," + this.time);
    }
}
