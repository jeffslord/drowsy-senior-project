import tensorflow as tf



def restore_session(fileDir):
    sess = tf.Session()
    saver = tf.train.import_meta_graph(fileDir + r"\my_model-500.meta")
    saver.restore(sess, tf.train.latest_checkpoint(fileDir))
    return sess
    # print(sess.run('W:0')) # Assuming W was a name giving to a tf.Variable

def freeze_graph(fileDir):
    sess = restore_session(fileDir)
    output_graph_def = tf.graph_util.convert_variables_to_constants(
        sess,
        tf.get_default_graph().as_graph_def(),
    )


if __name__ == '__main__':
    sess = restore_session(r"D:\Development\Senior Project\models")
